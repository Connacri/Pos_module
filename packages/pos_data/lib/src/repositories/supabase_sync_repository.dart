import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../data_sources/supabase_config.dart';
import '../models/objectbox/category_entity.dart';
import '../models/objectbox/customer_entity.dart';
import '../models/objectbox/invoice_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import '../../objectbox.g.dart';

class SupabaseSyncRepository implements SyncRepository {
  SupabaseSyncRepository({required this.connectivityService})
      : _productBox = ObjectboxDatabase.box<ProductEntity>(),
        _categoryBox = ObjectboxDatabase.box<CategoryEntity>(),
        _customerBox = ObjectboxDatabase.box<CustomerEntity>(),
        _saleBox = ObjectboxDatabase.box<SaleEntity>(),
        _invoiceBox = ObjectboxDatabase.box<InvoiceEntity>() {
    connectivityService.addListener(_onConnectivityChanged);
  }

  final ConnectivityService connectivityService;
  final Box<ProductEntity> _productBox;
  final Box<CategoryEntity> _categoryBox;
  final Box<CustomerEntity> _customerBox;
  final Box<SaleEntity> _saleBox;
  final Box<InvoiceEntity> _invoiceBox;

  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  void _onConnectivityChanged() {
    _onlineController.add(connectivityService.isOnline);
  }

  @override
  Stream<bool> watchOnline() {
    return _onlineController.stream;
  }

  @override
  Future<DateTime?> lastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(AppConstants.keyLastSync);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> syncAll() async {
    if (!SupabaseConfig.isConfigured) {
      throw const SyncFailure('Supabase n\'est pas configuré');
    }
    if (!connectivityService.isOnline) {
      throw const NetworkFailure('Pas de connexion internet');
    }

    AppLogger.info('Synchronisation avec Supabase...');
    await _pushPending();
    await _pullProducts();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.keyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
    AppLogger.info('Synchronisation terminée');
  }

  Future<void> _pushPending() async {
    final client = Supabase.instance.client;

    final pendingProducts = _productBox
        .query(ProductEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final p in pendingProducts) {
      await client
          .from('products')
          .upsert(_productToMap(p), onConflict: 'id');
      _productBox.put(p..syncStatus = SyncStatus.synced.index);
    }

    final pendingCategories = _categoryBox
        .query(CategoryEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final c in pendingCategories) {
      await client
          .from('categories')
          .upsert(_categoryToMap(c), onConflict: 'id');
      _categoryBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    final pendingCustomers = _customerBox
        .query(CustomerEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final c in pendingCustomers) {
      await client
          .from('customers')
          .upsert(_customerToMap(c), onConflict: 'id');
      _customerBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    await _pushSales(client);
    await _pushInvoices(client);
  }

  Future<void> _pushSales(SupabaseClient client) async {
    final pendingSales = _saleBox
        .query(SaleEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final s in pendingSales) {
      try {
        await client.from('sales').upsert(_saleToMap(s), onConflict: 'id');
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        s.saleNumber =
            await _nextRemoteNumber(client, 'sales', 'sale_number');
        s.updatedAt = DateTime.now();
        await client.from('sales').upsert(_saleToMap(s), onConflict: 'id');
      }
      _saleBox.put(s..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushInvoices(SupabaseClient client) async {
    final pendingInvoices = _invoiceBox
        .query(InvoiceEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final i in pendingInvoices) {
      try {
        await client.from('invoices').upsert(_invoiceToMap(i), onConflict: 'id');
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        i.invoiceNumber =
            await _nextRemoteNumber(client, 'invoices', 'invoice_number');
        i.updatedAt = DateTime.now();
        await client.from('invoices').upsert(_invoiceToMap(i), onConflict: 'id');
      }
      _invoiceBox.put(i..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<String> _nextRemoteNumber(
    SupabaseClient client,
    String table,
    String column,
  ) async {
    final rows = await client.from(table).select(column);
    var max = 0;
    for (final row in rows) {
      final raw = row[column];
      final value = raw is num ? raw.toInt() : int.tryParse('$raw');
      if (value != null && value > max) max = value;
    }
    return (max + 1).toString().padLeft(6, '0');
  }

  Future<void> _pullProducts() async {
    final client = Supabase.instance.client;
    final rows = await client.from('products').select();
    for (final row in rows) {
      final sku = row['sku'] as String?;
      if (sku == null) continue;

      final existing = _productBox
          .query(ProductEntity_.sku.equals(sku, caseSensitive: false))
          .build()
          .findFirst();

      if (existing == null) {
        _productBox.put(_productFromMap(row));
      } else {
        final e = existing;
        e
          ..name = row['name'] as String? ?? e.name
          ..price = (row['price'] as num?)?.toDouble() ?? e.price
          ..stock = (row['stock'] as num?)?.toDouble() ?? e.stock
          ..updatedAt = DateTime.now();
        _productBox.put(e);
      }
    }
  }

  Map<String, dynamic> _productToMap(ProductEntity p) {
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
      'image_url': p.imageUrl,
      'is_active': p.isActive,
      'created_at': p.createdAt.toIso8601String(),
      'updated_at': p.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _categoryToMap(CategoryEntity c) {
    return {
      'id': c.id,
      'name': c.name,
      'parent_id': c.parentId,
      'sort_order': c.sortOrder,
      'is_active': c.isActive,
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _customerToMap(CustomerEntity c) {
    return {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'company': c.company,
      'tax_id': c.taxId,
      'notes': c.notes,
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _saleToMap(SaleEntity s) {
    return {
      'id': s.id,
      'sale_number': s.saleNumber,
      'customer_id': s.customerId,
      'cashier_id': s.cashierId,
      'payment_method': s.paymentMethod,
      'status': s.status,
      'discount_total': s.discountTotal,
      'total': _saleTotal(s),
      'created_at': s.createdAt.toIso8601String(),
      'updated_at': s.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _invoiceToMap(InvoiceEntity i) {
    return {
      'id': i.id,
      'invoice_number': i.invoiceNumber,
      'sale_id': i.saleId,
      'customer_id': i.customerId,
      'status': i.status,
      'discount_total': i.discountTotal,
      'company_name': i.companyName,
      'company_address': i.companyAddress,
      'company_tax_id': i.companyTaxId,
      'due_date': i.dueDate?.toIso8601String(),
      'created_at': i.createdAt.toIso8601String(),
      'updated_at': i.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  double _saleTotal(SaleEntity s) {
    final items = ObjectboxDatabase.box<SaleItemEntity>()
        .query(SaleItemEntity_.saleId.equals(s.id))
        .build()
        .find();
    var subtotal = 0.0;
    for (final item in items) {
      subtotal += (item.unitPrice * item.quantity) * (1 + item.taxRate);
    }
    return subtotal - s.discountTotal;
  }

  ProductEntity _productFromMap(Map<String, dynamic> row) {
    final now = DateTime.now();
    return ProductEntity()
      ..id = 0
      ..sku = row['sku'] as String? ?? ''
      ..name = row['name'] as String? ?? ''
      ..description = row['description'] as String?
      ..price = (row['price'] as num?)?.toDouble() ?? 0
      ..costPrice = (row['cost_price'] as num?)?.toDouble() ?? 0
      ..taxRate = (row['tax_rate'] as num?)?.toDouble() ?? AppConstants.defaultTaxRate
      ..stock = (row['stock'] as num?)?.toDouble() ?? 0
      ..barcode = row['barcode'] as String?
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SyncStatus.synced.index;
  }

  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    _onlineController.close();
  }
}
