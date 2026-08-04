import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../data_sources/supabase_config.dart';
import '../models/objectbox/category_entity.dart';
import '../models/objectbox/customer_entity.dart';
import '../models/objectbox/invoice_entity.dart';
import '../models/objectbox/invoice_item_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/return_item_entity.dart';
import '../models/objectbox/return_record_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import '../../objectbox.g.dart';

class SupabaseSyncRepository implements SyncRepository {
  SupabaseSyncRepository({required this.connectivityService})
      : _productBox = ObjectboxDatabase.box<ProductEntity>(),
        _categoryBox = ObjectboxDatabase.box<CategoryEntity>(),
        _customerBox = ObjectboxDatabase.box<CustomerEntity>(),
        _saleBox = ObjectboxDatabase.box<SaleEntity>(),
        _invoiceBox = ObjectboxDatabase.box<InvoiceEntity>(),
        _returnBox = ObjectboxDatabase.box<ReturnRecordEntity>() {
    connectivityService.addListener(_onConnectivityChanged);
  }

  final ConnectivityService connectivityService;
  final Box<ProductEntity> _productBox;
  final Box<CategoryEntity> _categoryBox;
  final Box<CustomerEntity> _customerBox;
  final Box<SaleEntity> _saleBox;
  final Box<InvoiceEntity> _invoiceBox;
  final Box<ReturnRecordEntity> _returnBox;

  int? _deviceId;

  /// Multiplicateur qui sépare les ID locaux de chaque appareil sur le serveur.
  ///
  /// Chaque appareil reçoit un identifiant unique et pousse ses enregistrements
  /// avec un ID distant = deviceId * [_remoteIdSpace] + idLocal. Cela évite que
  /// deux appareils écrasent les lignes de l'autre pendant les upserts (conflit
  /// sur la clé primaire 'id' de Supabase).
  static const int _remoteIdSpace = 1000000;

  /// Calcule l'ID distant d'un enregistrement local.
  int _remoteId(int localId) {
    if (localId <= 0) return localId;
    return _deviceId! * _remoteIdSpace + localId;
  }

  Future<void> _ensureDeviceId() async {
    if (_deviceId != null) return;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getInt(AppConstants.keyDeviceId);
    if (id == null || id < 1) {
      id = Random().nextInt(1 << 22) + 1;
      await prefs.setInt(AppConstants.keyDeviceId, id);
    }
    _deviceId = id;
  }

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
    await _ensureDeviceId();
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

    // Les produits, catégories et clients sont poussés intégralement à chaque
    // synchronisation (upsert idempotent). Cela garantit que la base distante
    // est reconstruite même après avoir été vidée.
    for (final p in _productBox.getAll()) {
      await client.from('products').upsert(_productToMap(p), onConflict: 'id');
      _productBox.put(p..syncStatus = SyncStatus.synced.index);
    }

    for (final c in _categoryBox.getAll()) {
      await client.from('categories').upsert(_categoryToMap(c), onConflict: 'id');
      _categoryBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    for (final c in _customerBox.getAll()) {
      await client.from('customers').upsert(_customerToMap(c), onConflict: 'id');
      _customerBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    await _pushSales(client);
    await _pushInvoices(client);
    await _pushReturns(client);
  }

  Future<void> _pushSales(SupabaseClient client) async {
    final pendingSales = _saleBox
        .query(SaleEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final s in pendingSales) {
      await _pushWithUniqueNumber(
        client: client,
        table: 'sales',
        numberColumn: 'sale_number',
        toMap: () => _saleToMap(s),
        applyNumber: (number) {
          s.saleNumber = number;
          s.updatedAt = DateTime.now();
        },
      );
      await _pushSaleItems(client, s);
      _saleBox.put(s..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushInvoices(SupabaseClient client) async {
    final pendingInvoices = _invoiceBox
        .query(InvoiceEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final i in pendingInvoices) {
      await _pushWithUniqueNumber(
        client: client,
        table: 'invoices',
        numberColumn: 'invoice_number',
        toMap: () => _invoiceToMap(i),
        applyNumber: (number) {
          i.invoiceNumber = number;
          i.updatedAt = DateTime.now();
        },
      );
      await _pushInvoiceItems(client, i);
      _invoiceBox.put(i..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushReturns(SupabaseClient client) async {
    final pendingReturns = _returnBox
        .query(ReturnRecordEntity_.syncStatus.equals(SyncStatus.pending.index))
        .build()
        .find();
    for (final r in pendingReturns) {
      await client
          .from('returns')
          .upsert(_returnToMap(r), onConflict: 'id');
      await _pushReturnItems(client, r);
      _returnBox.put(r..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushReturnItems(SupabaseClient client, ReturnRecordEntity r) async {
    final items = ObjectboxDatabase.box<ReturnItemEntity>()
        .query(ReturnItemEntity_.returnId.equals(r.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client
          .from('return_items')
          .delete()
          .eq('return_id', _remoteId(r.id));
      await client
          .from('return_items')
          .insert(items.map(_returnItemToMap).toList());
    } catch (e) {
      AppLogger.warning('Échec synchronisation des lignes du retour ${r.id}: $e');
    }
  }

  Map<String, dynamic> _returnToMap(ReturnRecordEntity r) {
    return {
      'id': _remoteId(r.id),
      'sale_id': _remoteId(r.saleId),
      'sale_number': r.saleNumber,
      'customer_id': _remoteId(r.customerId),
      'reason': r.reason,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _returnItemToMap(ReturnItemEntity item) {
    return {
      'return_id': _remoteId(item.returnId),
      'product_id': _remoteId(item.productId),
      'description': item.description,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'tax_rate': item.taxRate,
      'discount': item.discount,
    };
  }

  /// Upsert d'une ligne portant un numéro unique (sale_number / invoice_number).
  ///
  /// En cas de conflit 23505 (numéro déjà utilisé sur le serveur), le numéro est
  /// régénéré depuis le max distant et le upsert est réessayé. Les tentatives
  /// successives requestionnent le max à chaque fois pour éviter les collisions
  /// entre plusieurs appareils qui synchronisent en même temps.
  Future<void> _pushWithUniqueNumber({
    required SupabaseClient client,
    required String table,
    required String numberColumn,
    required Map<String, dynamic> Function() toMap,
    required void Function(String number) applyNumber,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await client.from(table).upsert(toMap(), onConflict: 'id');
        return;
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        if (attempt == maxAttempts - 1) rethrow;
        applyNumber(await _nextRemoteNumber(client, table, numberColumn));
      }
    }
  }

  Future<void> _pushSaleItems(SupabaseClient client, SaleEntity s) async {
    final items = ObjectboxDatabase.box<SaleItemEntity>()
        .query(SaleItemEntity_.saleId.equals(s.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client
          .from('sale_items')
          .delete()
          .eq('sale_id', _remoteId(s.id));
      await client.from('sale_items').insert(items.map(_saleItemToMap).toList());
    } catch (e) {
      AppLogger.warning('Échec synchronisation des lignes de la vente ${s.id}: $e');
    }
  }

  Future<void> _pushInvoiceItems(SupabaseClient client, InvoiceEntity i) async {
    final items = ObjectboxDatabase.box<InvoiceItemEntity>()
        .query(InvoiceItemEntity_.invoiceId.equals(i.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client
          .from('invoice_items')
          .delete()
          .eq('invoice_id', _remoteId(i.id));
      await client
          .from('invoice_items')
          .insert(items.map(_invoiceItemToMap).toList());
    } catch (e) {
      AppLogger.warning(
        'Échec synchronisation des lignes de la facture ${i.id}: $e',
      );
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
        final remoteUpdatedAt = DateTime.tryParse(
          row['updated_at'] as String? ?? '',
        );
        e
          ..name = row['name'] as String? ?? e.name
          ..price = (row['price'] as num?)?.toDouble() ?? e.price
          ..stock = (row['stock'] as num?)?.toDouble() ?? e.stock;
        if (remoteUpdatedAt != null &&
            remoteUpdatedAt.isAfter(e.updatedAt)) {
          e.updatedAt = remoteUpdatedAt;
        }
        _productBox.put(e);
      }
    }
  }

  Map<String, dynamic> _productToMap(ProductEntity p) {
    return {
      'id': _remoteId(p.id),
      'sku': p.sku,
      'name': p.name,
      'description': p.description,
      'category_id': _remoteId(p.categoryId),
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
      'id': _remoteId(c.id),
      'name': c.name,
      'parent_id': _remoteId(c.parentId),
      'sort_order': c.sortOrder,
      'is_active': c.isActive,
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _customerToMap(CustomerEntity c) {
    return {
      'id': _remoteId(c.id),
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
      'id': _remoteId(s.id),
      'sale_number': s.saleNumber,
      'customer_id': _remoteId(s.customerId),
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
      'id': _remoteId(i.id),
      'invoice_number': i.invoiceNumber,
      'sale_id': _remoteId(i.saleId),
      'customer_id': _remoteId(i.customerId),
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
    var tax = 0.0;
    for (final item in items) {
      final lineSubtotal = (item.unitPrice * item.quantity) - item.discount;
      subtotal += lineSubtotal;
      tax += lineSubtotal * item.taxRate;
    }
    return (subtotal + tax) - s.discountTotal;
  }

  Map<String, dynamic> _saleItemToMap(SaleItemEntity item) {
    return {
      'sale_id': _remoteId(item.saleId),
      'product_id': _remoteId(item.productId),
      'product_name': item.productName,
      'sku': item.sku,
      'unit_price': item.unitPrice,
      'cost_price': item.costPrice,
      'tax_rate': item.taxRate,
      'quantity': item.quantity,
      'discount': item.discount,
    };
  }

  Map<String, dynamic> _invoiceItemToMap(InvoiceItemEntity item) {
    return {
      'invoice_id': _remoteId(item.invoiceId),
      'product_id': _remoteId(item.productId),
      'description': item.description,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'tax_rate': item.taxRate,
      'discount': item.discount,
    };
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
