import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data_sources/objectbox_database.dart';
import '../data_sources/supabase_config.dart';
import '../models/objectbox/category_entity.dart';
import '../models/objectbox/customer_entity.dart';
import '../models/objectbox/invoice_entity.dart';
import '../models/objectbox/invoice_item_entity.dart';
import '../models/objectbox/payment_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import 'seed_data.dart';

class SeedService {
  SeedService._();

  static Future<bool> seedIfEmpty() async {
    if (ObjectboxDatabase.box<ProductEntity>().count() > 0) {
      return false;
    }
    await seedObjectBox();
    return true;
  }

  static Future<void> seedObjectBox() async {
    final categoryBox = ObjectboxDatabase.box<CategoryEntity>();
    final productBox = ObjectboxDatabase.box<ProductEntity>();
    final customerBox = ObjectboxDatabase.box<CustomerEntity>();
    final saleBox = ObjectboxDatabase.box<SaleEntity>();
    final saleItemBox = ObjectboxDatabase.box<SaleItemEntity>();
    final invoiceBox = ObjectboxDatabase.box<InvoiceEntity>();
    final invoiceItemBox = ObjectboxDatabase.box<InvoiceItemEntity>();
    final paymentBox = ObjectboxDatabase.box<PaymentEntity>();

    if (categoryBox.count() == 0) {
      categoryBox.putMany(
        SeedData.categories.map(_toCategoryEntity).toList(),
      );
    }

    if (productBox.count() == 0) {
      productBox.putMany(
        SeedData.products.map(_toProductEntity).toList(),
      );
    }

    if (customerBox.count() == 0) {
      customerBox.putMany(
        SeedData.customers.map(_toCustomerEntity).toList(),
      );
    }

    if (saleBox.count() == 0) {
      for (final sale in SeedData.sales) {
        final id = saleBox.put(_toSaleEntity(sale));
        saleItemBox.putMany(
          sale.items
              .map((item) => _toSaleItemEntity(item, id))
              .toList(),
        );
      }
    }

    if (invoiceBox.count() == 0) {
      for (final invoice in SeedData.invoices) {
        final id = invoiceBox.put(_toInvoiceEntity(invoice));
        invoiceItemBox.putMany(
          invoice.items
              .map((item) => _toInvoiceItemEntity(item, id))
              .toList(),
        );
      }
    }

    if (paymentBox.count() == 0) {
      final payments = SeedData.payments.map((p) {
        final amount = p.amount == 0 ? _paymentAmountFor(p) : p.amount;
        return PaymentEntity()
          ..id = p.id
          ..amount = amount
          ..method = p.method.index
          ..saleId = p.saleId ?? 0
          ..invoiceId = p.invoiceId ?? 0
          ..reference = p.reference
          ..paidAt = p.paidAt
          ..syncStatus = SyncStatus.synced.index;
      }).toList();
      paymentBox.putMany(payments);
    }
  }

  static Future<void> seedSupabase() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    final client = Supabase.instance.client;

    await client
        .from('categories')
        .upsert(
          SeedData.categories.map(_categoryToMap).toList(),
          onConflict: 'id',
        );
    await client
        .from('products')
        .upsert(
          SeedData.products.map(_productToMap).toList(),
          onConflict: 'id',
        );
    await client
        .from('customers')
        .upsert(
          SeedData.customers.map(_customerToMap).toList(),
          onConflict: 'id',
        );
    await client
        .from('sales')
        .upsert(
          SeedData.sales.map((s) => _saleToMap(s)).toList(),
          onConflict: 'id',
        );

    final saleItems = <Map<String, dynamic>>[];
    for (final sale in SeedData.sales) {
      for (final item in sale.items) {
        saleItems.add(_saleItemToMap(sale, item));
      }
    }
    await client.from('sale_items').upsert(saleItems);

    await client
        .from('invoices')
        .upsert(
          SeedData.invoices.map(_invoiceToMap).toList(),
          onConflict: 'id',
        );

    final invoiceItems = <Map<String, dynamic>>[];
    for (final invoice in SeedData.invoices) {
      for (final item in invoice.items) {
        invoiceItems.add(_invoiceItemToMap(invoice, item));
      }
    }
    await client.from('invoice_items').upsert(invoiceItems);

    await client
        .from('payments')
        .upsert(
          SeedData.payments
              .map((p) => _paymentToMap(p))
              .toList(),
          onConflict: 'id',
        );
  }

  static double _paymentAmountFor(SeedPayment payment) {
    if (payment.invoiceId != null) {
      final invoice = SeedData.invoices
          .where((i) => i.id == payment.invoiceId)
          .firstOrNull;
      if (invoice != null) return _invoiceTotal(invoice);
    }
    final sale = SeedData.sales
        .where((s) => s.id == payment.saleId)
        .firstOrNull;
    if (sale != null) return _saleTotal(sale);
    return 0;
  }

  static double _saleTotal(SeedSale sale) {
    final subtotal = sale.items.fold<double>(
      0,
      (sum, item) =>
          sum + (_unitPrice(item.productId) * item.quantity) - item.discount,
    );
    final tax = sale.items.fold<double>(
      0,
      (sum, item) {
        final line = (_unitPrice(item.productId) * item.quantity) - item.discount;
        final rate = _taxRate(item.productId);
        return sum + line * rate;
      },
    );
    return (subtotal + tax) - sale.discountTotal;
  }

  static double _invoiceTotal(SeedInvoice invoice) {
    final subtotal = invoice.items.fold<double>(
      0,
      (sum, item) =>
          sum + (item.unitPrice! * item.quantity) - item.discount,
    );
    final tax = invoice.items.fold<double>(
      0,
      (sum, item) {
        final line = (item.unitPrice! * item.quantity) - item.discount;
        return sum + line * item.taxRate;
      },
    );
    return (subtotal + tax) - invoice.discountTotal;
  }

  static double _unitPrice(int productId) {
    final product = SeedData.productById[productId];
    return product?.price ?? 0;
  }

  static double _taxRate(int productId) {
    final product = SeedData.productById[productId];
    return product?.taxRate ?? AppConstants.defaultTaxRate;
  }

  static CategoryEntity _toCategoryEntity(SeedCategory c) {
    return CategoryEntity()
      ..id = c.id
      ..name = c.name
      ..parentId = c.parentId ?? 0
      ..sortOrder = c.sortOrder
      ..isActive = c.isActive
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.synced.index;
  }

  static ProductEntity _toProductEntity(SeedProduct p) {
    return ProductEntity()
      ..id = p.id
      ..sku = p.sku
      ..name = p.name
      ..description = p.description
      ..categoryId = p.categoryId
      ..price = p.price
      ..costPrice = p.costPrice
      ..taxRate = p.taxRate
      ..stock = p.stock
      ..lowStockThreshold = p.lowStockThreshold
      ..barcode = p.barcode
      ..isActive = p.isActive
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.synced.index;
  }

  static CustomerEntity _toCustomerEntity(SeedCustomer c) {
    return CustomerEntity()
      ..id = c.id
      ..name = c.name
      ..phone = c.phone
      ..email = c.email
      ..address = c.address
      ..company = c.company
      ..taxId = c.taxId
      ..notes = c.notes
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.synced.index;
  }

  static SaleEntity _toSaleEntity(SeedSale s) {
    return SaleEntity()
      ..id = s.id
      ..saleNumber = s.saleNumber
      ..customerId = s.customerId ?? 0
      ..cashierId = 0
      ..paymentMethod = s.paymentMethod.index
      ..status = s.status.index
      ..discountTotal = s.discountTotal
      ..createdAt = s.createdAt
      ..updatedAt = s.createdAt
      ..syncStatus = SyncStatus.synced.index;
  }

  static SaleItemEntity _toSaleItemEntity(SeedSaleItem item, int saleId) {
    final product = SeedData.productById[item.productId];
    return SaleItemEntity()
      ..saleId = saleId
      ..productId = item.productId
      ..productName = product?.name ?? ''
      ..sku = product?.sku ?? ''
      ..unitPrice = item.unitPrice ?? product?.price ?? 0
      ..costPrice = product?.costPrice ?? 0
      ..taxRate = product?.taxRate ?? AppConstants.defaultTaxRate
      ..quantity = item.quantity
      ..discount = item.discount;
  }

  static InvoiceEntity _toInvoiceEntity(SeedInvoice i) {
    return InvoiceEntity()
      ..id = i.id
      ..invoiceNumber = i.invoiceNumber
      ..saleId = i.saleId ?? 0
      ..customerId = i.customerId ?? 0
      ..status = i.status.index
      ..discountTotal = i.discountTotal
      ..dueDate = i.dueDate
      ..createdAt = i.createdAt
      ..updatedAt = i.createdAt
      ..syncStatus = SyncStatus.synced.index;
  }

  static InvoiceItemEntity _toInvoiceItemEntity(
    SeedInvoiceItem item,
    int invoiceId,
  ) {
    final product = SeedData.productById[item.productId];
    return InvoiceItemEntity()
      ..invoiceId = invoiceId
      ..productId = item.productId
      ..description = item.description
      ..unitPrice = item.unitPrice ?? product?.price ?? 0
      ..quantity = item.quantity
      ..taxRate = item.taxRate
      ..discount = item.discount;
  }

  static Map<String, dynamic> _categoryToMap(SeedCategory c) {
    return {
      'id': c.id,
      'name': c.name,
      'parent_id': c.parentId ?? 0,
      'sort_order': c.sortOrder,
      'is_active': c.isActive,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  static Map<String, dynamic> _productToMap(SeedProduct p) {
    return {
      'id': p.id,
      'sku': p.sku,
      'name': p.name,
      'description': p.description,
      'category_id': p.categoryId,
      'price': p.price,
      'cost_price': p.costPrice,
      'tax_rate': p.taxRate,
      'stock': p.stock,
      'low_stock_threshold': p.lowStockThreshold,
      'barcode': p.barcode,
      'image_url': null,
      'is_active': p.isActive,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  static Map<String, dynamic> _customerToMap(SeedCustomer c) {
    return {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'company': c.company,
      'tax_id': c.taxId,
      'notes': c.notes,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  static Map<String, dynamic> _saleToMap(SeedSale s) {
    return {
      'id': s.id,
      'sale_number': s.saleNumber,
      'customer_id': s.customerId ?? 0,
      'cashier_id': 0,
      'payment_method': s.paymentMethod.index,
      'status': s.status.index,
      'discount_total': s.discountTotal,
      'total': _saleTotal(s),
      'created_at': s.createdAt.toIso8601String(),
      'updated_at': s.createdAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  static Map<String, dynamic> _saleItemToMap(SeedSale sale, SeedSaleItem item) {
    final product = SeedData.productById[item.productId];
    return {
      'sale_id': sale.id,
      'product_id': item.productId,
      'product_name': product?.name ?? '',
      'sku': product?.sku ?? '',
      'unit_price': item.unitPrice ?? product?.price ?? 0,
      'cost_price': product?.costPrice ?? 0,
      'tax_rate': product?.taxRate ?? AppConstants.defaultTaxRate,
      'quantity': item.quantity,
      'discount': item.discount,
    };
  }

  static Map<String, dynamic> _invoiceToMap(SeedInvoice i) {
    return {
      'id': i.id,
      'invoice_number': i.invoiceNumber,
      'sale_id': i.saleId ?? 0,
      'customer_id': i.customerId ?? 0,
      'status': i.status.index,
      'discount_total': i.discountTotal,
      'company_name': 'POS Module',
      'company_address': 'Alger, Algérie',
      'company_tax_id': '099900000000',
      'due_date': i.dueDate?.toIso8601String(),
      'created_at': i.createdAt.toIso8601String(),
      'updated_at': i.createdAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  static Map<String, dynamic> _invoiceItemToMap(
    SeedInvoice invoice,
    SeedInvoiceItem item,
  ) {
    final product = SeedData.productById[item.productId];
    return {
      'invoice_id': invoice.id,
      'product_id': item.productId,
      'description': item.description,
      'unit_price': item.unitPrice ?? product?.price ?? 0,
      'quantity': item.quantity,
      'tax_rate': item.taxRate,
      'discount': item.discount,
    };
  }

  static Map<String, dynamic> _paymentToMap(SeedPayment p) {
    final amount = p.amount == 0 ? _paymentAmountFor(p) : p.amount;
    return {
      'id': p.id,
      'amount': amount,
      'method': p.method.index,
      'sale_id': p.saleId ?? 0,
      'invoice_id': p.invoiceId ?? 0,
      'reference': p.reference,
      'paid_at': p.paidAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }
}
