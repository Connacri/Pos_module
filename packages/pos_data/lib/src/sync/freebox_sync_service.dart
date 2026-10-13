import 'dart:convert';
import 'package:freebox_sync/freebox_sync.dart';
import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/category_entity.dart';
import '../models/objectbox/customer_entity.dart';
import '../models/objectbox/invoice_entity.dart';
import '../models/objectbox/invoice_item_entity.dart';
import '../models/objectbox/payment_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/return_item_entity.dart';
import '../models/objectbox/return_record_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';

/// Service reliant ObjectBox avec le moteur P2P FreeBoxSync.
/// Permet la synchronisation en temps réel multi-postes sans serveur central.
class FreeboxSyncService {
  FreeboxSyncService._();

  static const int entityProduct = 1;
  static const int entityCategory = 2;
  static const int entityCustomer = 3;
  static const int entitySale = 4;
  static const int entityInvoice = 5;
  static const int entityReturn = 6;
  static const int entityPayment = 7;

  static bool _initialized = false;

  static Future<void> initialize({String? stationName}) async {
    if (_initialized) return;
    _initialized = true;

    final sync = FreeBoxSync.instance;
    await sync.initialize(
      store: ObjectboxDatabase.store,
      stationName: stationName ?? 'Poste Caisse',
    );

    _registerHandlers();
  }

  static void _registerHandlers() {
    final sync = FreeBoxSync.instance;

    // 1. Produit
    sync.registerEntityHandler(entityProduct, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final box = ObjectboxDatabase.box<ProductEntity>();
        var entity = box.get(objectId) ?? ProductEntity();
        entity.id = objectId;
        entity.sku = data['sku'] ?? entity.sku;
        entity.name = data['name'] ?? entity.name;
        entity.description = data['description'];
        entity.categoryId = data['categoryId'] ?? 0;
        entity.price = (data['price'] as num?)?.toDouble() ?? entity.price;
        entity.costPrice = (data['costPrice'] as num?)?.toDouble() ?? entity.costPrice;
        entity.taxRate = (data['taxRate'] as num?)?.toDouble() ?? entity.taxRate;
        entity.stock = (data['stock'] as num?)?.toDouble() ?? entity.stock;
        entity.lowStockThreshold = (data['lowStockThreshold'] as num?)?.toDouble() ?? entity.lowStockThreshold;
        entity.barcode = data['barcode'];
        entity.imageUrl = data['imageUrl'];
        entity.isActive = data['isActive'] ?? true;
        entity.updatedAt = DateTime.now();
        box.put(entity);
      } catch (_) {}
    });

    // 2. Catégorie
    sync.registerEntityHandler(entityCategory, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final box = ObjectboxDatabase.box<CategoryEntity>();
        var entity = box.get(objectId) ?? CategoryEntity();
        entity.id = objectId;
        entity.name = data['name'] ?? entity.name;
        entity.parentId = data['parentId'] ?? 0;
        entity.sortOrder = data['sortOrder'] ?? 0;
        entity.isActive = data['isActive'] ?? true;
        entity.updatedAt = DateTime.now();
        box.put(entity);
      } catch (_) {}
    });

    // 3. Client
    sync.registerEntityHandler(entityCustomer, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final box = ObjectboxDatabase.box<CustomerEntity>();
        var entity = box.get(objectId) ?? CustomerEntity();
        entity.id = objectId;
        entity.name = data['name'] ?? entity.name;
        entity.phone = data['phone'];
        entity.email = data['email'];
        entity.address = data['address'];
        entity.company = data['company'];
        entity.taxId = data['taxId'];
        entity.notes = data['notes'];
        entity.updatedAt = DateTime.now();
        box.put(entity);
      } catch (_) {}
    });

    // 4. Vente
    sync.registerEntityHandler(entitySale, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final saleBox = ObjectboxDatabase.box<SaleEntity>();
        final itemBox = ObjectboxDatabase.box<SaleItemEntity>();
        var entity = saleBox.get(objectId) ?? SaleEntity();
        entity.id = objectId;
        entity.saleNumber = data['saleNumber'] ?? entity.saleNumber;
        entity.customerId = data['customerId'] ?? 0;
        entity.paymentMethod = data['paymentMethod'] ?? 0;
        entity.status = data['status'] ?? 0;
        entity.discountTotal = (data['discountTotal'] as num?)?.toDouble() ?? 0;
        entity.createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
        entity.updatedAt = DateTime.now();
        saleBox.put(entity);

        // Sauvegarde des articles de la vente
        final itemsRaw = data['items'] as List<dynamic>?;
        if (itemsRaw != null) {
          for (final itemMap in itemsRaw) {
            final m = itemMap as Map<String, dynamic>;
            final itemEntity = SaleItemEntity()
              ..saleId = entity.id
              ..productId = m['productId'] ?? 0
              ..productName = m['productName'] ?? ''
              ..sku = m['sku'] ?? ''
              ..unitPrice = (m['unitPrice'] as num?)?.toDouble() ?? 0
              ..costPrice = (m['costPrice'] as num?)?.toDouble() ?? 0
              ..taxRate = (m['taxRate'] as num?)?.toDouble() ?? 0
              ..quantity = (m['quantity'] as num?)?.toDouble() ?? 0
              ..discount = (m['discount'] as num?)?.toDouble() ?? 0;
            itemBox.put(itemEntity);
          }
        }
      } catch (_) {}
    });

    // 5. Facture
    sync.registerEntityHandler(entityInvoice, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final invoiceBox = ObjectboxDatabase.box<InvoiceEntity>();
        final itemBox = ObjectboxDatabase.box<InvoiceItemEntity>();
        var entity = invoiceBox.get(objectId) ?? InvoiceEntity();
        entity.id = objectId;
        entity.invoiceNumber = data['invoiceNumber'] ?? entity.invoiceNumber;
        entity.saleId = data['saleId'] ?? 0;
        entity.customerId = data['customerId'] ?? 0;
        entity.status = data['status'] ?? 0;
        entity.discountTotal = (data['discountTotal'] as num?)?.toDouble() ?? 0;
        entity.companyName = data['companyName'];
        entity.companyAddress = data['companyAddress'];
        entity.companyTaxId = data['companyTaxId'];
        if (data['dueDate'] != null) {
          entity.dueDate = DateTime.tryParse(data['dueDate']);
        }
        entity.createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
        entity.updatedAt = DateTime.now();
        invoiceBox.put(entity);

        final itemsRaw = data['items'] as List<dynamic>?;
        if (itemsRaw != null) {
          for (final itemMap in itemsRaw) {
            final m = itemMap as Map<String, dynamic>;
            final itemEntity = InvoiceItemEntity()
              ..invoiceId = entity.id
              ..productId = m['productId'] ?? 0
              ..description = m['description'] ?? ''
              ..unitPrice = (m['unitPrice'] as num?)?.toDouble() ?? 0
              ..quantity = (m['quantity'] as num?)?.toDouble() ?? 0
              ..taxRate = (m['taxRate'] as num?)?.toDouble() ?? 0
              ..discount = (m['discount'] as num?)?.toDouble() ?? 0;
            itemBox.put(itemEntity);
          }
        }
      } catch (_) {}
    });

    // 6. Retour
    sync.registerEntityHandler(entityReturn, (objectId, opCode, payload, hlc) {
      try {
        final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final returnBox = ObjectboxDatabase.box<ReturnRecordEntity>();
        final itemBox = ObjectboxDatabase.box<ReturnItemEntity>();
        var entity = returnBox.get(objectId) ?? ReturnRecordEntity();
        entity.id = objectId;
        entity.saleId = data['saleId'] ?? 0;
        entity.saleNumber = data['saleNumber'] ?? '';
        entity.customerId = data['customerId'] ?? 0;
        entity.reason = data['reason'];
        entity.createdAt = DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
        entity.updatedAt = DateTime.now();
        returnBox.put(entity);

        final itemsRaw = data['items'] as List<dynamic>?;
        if (itemsRaw != null) {
          for (final itemMap in itemsRaw) {
            final m = itemMap as Map<String, dynamic>;
            final itemEntity = ReturnItemEntity()
              ..returnId = entity.id
              ..productId = m['productId'] ?? 0
              ..description = m['description'] ?? ''
              ..unitPrice = (m['unitPrice'] as num?)?.toDouble() ?? 0
              ..quantity = (m['quantity'] as num?)?.toDouble() ?? 0
              ..taxRate = (m['taxRate'] as num?)?.toDouble() ?? 0
              ..discount = (m['discount'] as num?)?.toDouble() ?? 0;
            itemBox.put(itemEntity);
          }
        }
      } catch (_) {}
    });
  }

  // Fonctions de diffusion P2P lors des mutations locales
  static void broadcastProduct(ProductEntity p) {
    FreeBoxSync.instance.broadcastEntityJson(entityProduct, p.id, {
      'id': p.id,
      'sku': p.sku,
      'name': p.name,
      'description': p.description,
      'categoryId': p.categoryId,
      'price': p.price,
      'costPrice': p.costPrice,
      'taxRate': p.taxRate,
      'stock': p.stock,
      'lowStockThreshold': p.lowStockThreshold,
      'barcode': p.barcode,
      'imageUrl': p.imageUrl,
      'isActive': p.isActive,
    });
  }

  static void broadcastCategory(CategoryEntity c) {
    FreeBoxSync.instance.broadcastEntityJson(entityCategory, c.id, {
      'id': c.id,
      'name': c.name,
      'parentId': c.parentId,
      'sortOrder': c.sortOrder,
      'isActive': c.isActive,
    });
  }

  static void broadcastCustomer(CustomerEntity c) {
    FreeBoxSync.instance.broadcastEntityJson(entityCustomer, c.id, {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'company': c.company,
      'taxId': c.taxId,
      'notes': c.notes,
    });
  }

  static void broadcastSale(SaleEntity s, List<SaleItemEntity> items) {
    FreeBoxSync.instance.broadcastEntityJson(entitySale, s.id, {
      'id': s.id,
      'saleNumber': s.saleNumber,
      'customerId': s.customerId,
      'paymentMethod': s.paymentMethod,
      'status': s.status,
      'discountTotal': s.discountTotal,
      'createdAt': s.createdAt.toIso8601String(),
      'items': items
          .map((i) => {
                'productId': i.productId,
                'productName': i.productName,
                'sku': i.sku,
                'unitPrice': i.unitPrice,
                'costPrice': i.costPrice,
                'taxRate': i.taxRate,
                'quantity': i.quantity,
                'discount': i.discount,
              })
          .toList(),
    });
  }

  static void broadcastInvoice(InvoiceEntity inv, List<InvoiceItemEntity> items) {
    FreeBoxSync.instance.broadcastEntityJson(entityInvoice, inv.id, {
      'id': inv.id,
      'invoiceNumber': inv.invoiceNumber,
      'saleId': inv.saleId,
      'customerId': inv.customerId,
      'status': inv.status,
      'discountTotal': inv.discountTotal,
      'companyName': inv.companyName,
      'companyAddress': inv.companyAddress,
      'companyTaxId': inv.companyTaxId,
      'dueDate': inv.dueDate?.toIso8601String(),
      'createdAt': inv.createdAt.toIso8601String(),
      'items': items
          .map((i) => {
                'productId': i.productId,
                'description': i.description,
                'unitPrice': i.unitPrice,
                'quantity': i.quantity,
                'taxRate': i.taxRate,
                'discount': i.discount,
              })
          .toList(),
    });
  }
}
