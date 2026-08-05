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
import '../models/objectbox/payment_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/return_item_entity.dart';
import '../models/objectbox/return_record_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import '../models/objectbox/sync_id_entity.dart';
import '../../objectbox.g.dart';

class SupabaseSyncRepository implements SyncRepository {
  SupabaseSyncRepository({required this.connectivityService})
      : _productBox = ObjectboxDatabase.box<ProductEntity>(),
        _categoryBox = ObjectboxDatabase.box<CategoryEntity>(),
        _customerBox = ObjectboxDatabase.box<CustomerEntity>(),
        _saleBox = ObjectboxDatabase.box<SaleEntity>(),
        _invoiceBox = ObjectboxDatabase.box<InvoiceEntity>(),
        _returnBox = ObjectboxDatabase.box<ReturnRecordEntity>(),
        _paymentBox = ObjectboxDatabase.box<PaymentEntity>(),
        _syncIdBox = ObjectboxDatabase.box<SyncIdEntity>() {
    connectivityService.addListener(_onConnectivityChanged);
  }

  final ConnectivityService connectivityService;
  final Box<ProductEntity> _productBox;
  final Box<CategoryEntity> _categoryBox;
  final Box<CustomerEntity> _customerBox;
  final Box<SaleEntity> _saleBox;
  final Box<InvoiceEntity> _invoiceBox;
  final Box<ReturnRecordEntity> _returnBox;
  final Box<PaymentEntity> _paymentBox;
  final Box<SyncIdEntity> _syncIdBox;

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

  /// Vrai si [remoteId] a été émis par cet appareil (espace d'ID local dédié).
  bool _isOwnRemoteId(int remoteId) {
    return remoteId > 0 && remoteId ~/ _remoteIdSpace == _deviceId;
  }

  /// ID local porté par un ID distant de cet appareil.
  int _localFromRemoteId(int remoteId) => remoteId % _remoteIdSpace;

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

  /// Traduit une clé étrangère distante en ID local ObjectBox.
  ///
  /// Utilise le mapping [SyncIdEntity] (ligne tirée depuis un autre appareil),
  /// sinon le décodage de l'espace d'ID local (ligne poussée par cet appareil),
  /// sinon 0 (référence inconnue, traitée comme absente).
  int _translateFk(String entityType, int remoteFk) {
    if (remoteFk <= 0) return 0;
    final local = _mappedLocalId(entityType, remoteFk);
    if (local != null) return local;
    if (_isOwnRemoteId(remoteFk)) return _localFromRemoteId(remoteFk);
    return 0;
  }

  /// ID local mappé à [remoteId] pour [entityType], ou null si inconnu.
  int? _mappedLocalId(String entityType, int remoteId) {
    final m = _syncIdBox
        .query(SyncIdEntity_.entityType.equals(entityType)
            .and(SyncIdEntity_.remoteId.equals(remoteId)))
        .build()
        .findFirst();
    return m?.localId;
  }

  /// Enregistre la correspondance [remoteId] ↔ [localId] pour [entityType].
  Future<void> _recordMapping(
    String entityType,
    int remoteId,
    int localId,
  ) async {
    if (remoteId <= 0 || localId <= 0) return;
    final existing = _syncIdBox
        .query(SyncIdEntity_.entityType.equals(entityType)
            .and(SyncIdEntity_.localId.equals(localId)))
        .build()
        .findFirst();
    if (existing != null) {
      if (existing.remoteId == remoteId) return;
      existing.remoteId = remoteId;
      _syncIdBox.put(existing);
      return;
    }
    _syncIdBox.put(SyncIdEntity()
      ..entityType = entityType
      ..remoteId = remoteId
      ..localId = localId);
  }

  /// Insère ou met à jour la ligne distante [remoteId] dans [box].
  ///
  /// Si un mapping existe (ou si l'ID distant appartient à cet appareil), la
  /// ligne locale est mise à jour en conservant son ID ; sinon une nouvelle
  /// ligne locale est créée et le mapping est enregistré. Le mapping est toujours
  /// garanti à la fin, ce qui évite tout doublon lors des synchronisations
  /// successives et permet de traduire les clés étrangères.
  Future<int> _ensureMapped<T>(
    String entityType,
    Box<T> box,
    int remoteId,
    T Function(int localId) build,
  ) async {
    var localId = _mappedLocalId(entityType, remoteId);
    if (localId == null && _isOwnRemoteId(remoteId)) {
      localId = _localFromRemoteId(remoteId);
    }
    // build(id) réutilise l'ID local existant (mise à jour) ou 0 pour laisser
    // ObjectBox attribuer un nouvel ID ; le mapping est ensuite enregistré.
    localId = box.put(build(localId ?? 0));
    await _recordMapping(entityType, remoteId, localId);
    return localId;
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
    await _pushAll();
    await _pullAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.keyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
    AppLogger.info('Synchronisation terminée');
  }

  /// Pousse intégralement toutes les tables locales vers Supabase.
  ///
  /// Chaque enregistrement est poussé via un upsert idempotent sur son ID
  /// distant (deviceId * 10^6 + idLocal). Les produits, catégories, clients,
  /// ventes, factures, paiements et retours sont poussés en totalité à chaque
  /// synchronisation : la base distante est donc toujours reconstruite/alignée
  /// sur la base locale (synchronisation forcée), indépendamment de l'état
  /// `syncStatus`. Le mapping [SyncIdEntity] est mis à jour pour chaque
  /// enregistrement poussé.
  Future<void> _pushAll() async {
    final client = Supabase.instance.client;

    for (final p in _productBox.getAll()) {
      final remoteId = await _pushProduct(client, p);
      await _recordMapping('product', remoteId, p.id);
      _productBox.put(p..syncStatus = SyncStatus.synced.index);
    }

    for (final c in _categoryBox.getAll()) {
      final remoteId = _remoteId(c.id);
      await client.from('categories').upsert(_categoryToMap(c), onConflict: 'id');
      await _recordMapping('category', remoteId, c.id);
      _categoryBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    for (final c in _customerBox.getAll()) {
      final remoteId = _remoteId(c.id);
      await client.from('customers').upsert(_customerToMap(c), onConflict: 'id');
      await _recordMapping('customer', remoteId, c.id);
      _customerBox.put(c..syncStatus = SyncStatus.synced.index);
    }

    await _pushSales(client);
    await _pushInvoices(client);
    await _pushPayments(client);
    await _pushReturns(client);
  }

  /// Pousse un produit avec upsert sur son ID distant et retourne l'ID distant
  /// réellement utilisé (qui peut différer en cas de fusion sur SKU existant).
  ///
  /// Si le SKU existe déjà sur le serveur sous un autre ID (données de démo aux
  /// IDs fixes, ou même SKU créé sur un autre appareil), la contrainte
  /// `products_sku_key` déclencherait une erreur 23505. On récupère alors l'ID
  /// distant réel de ce SKU et on fait l'upsert dessus pour fusionner au lieu
  /// d'interrompre toute la synchronisation.
  Future<int> _pushProduct(SupabaseClient client, ProductEntity p) async {
    try {
      await client.from('products').upsert(_productToMap(p), onConflict: 'id');
      return _remoteId(p.id);
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final rows = await client
          .from('products')
          .select('id')
          .eq('sku', p.sku)
          .limit(1);
      if (rows.isEmpty) rethrow;
      final remoteId = rows.first['id'] as int;
      await client.from('products').upsert(
        {..._productToMap(p), 'id': remoteId},
        onConflict: 'id',
      );
      return remoteId;
    }
  }

  Future<void> _pushSales(SupabaseClient client) async {
    // Pousse intégralement toutes les ventes locales (pas seulement celles en
    // attente) pour reconstruire/aligner la base distante à chaque sync forcée.
    for (final s in _saleBox.getAll()) {
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
      await _recordMapping('sale', _remoteId(s.id), s.id);
      _saleBox.put(s..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushInvoices(SupabaseClient client) async {
    // Pousse intégralement toutes les factures locales.
    for (final i in _invoiceBox.getAll()) {
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
      await _recordMapping('invoice', _remoteId(i.id), i.id);
      _invoiceBox.put(i..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushPayments(SupabaseClient client) async {
    // Les paiements sont poussés intégralement à chaque synchronisation comme
    // les produits/catégories/clients (upsert idempotent). La table `payments`
    // ne porte aucune contrainte unique : aucun conflit 23505 possible.
    for (final payment in _paymentBox.getAll()) {
      await client
          .from('payments')
          .upsert(_paymentToMap(payment), onConflict: 'id');
      await _recordMapping(
        'payment',
        _remoteId(payment.id),
        payment.id,
      );
      _paymentBox.put(payment..syncStatus = SyncStatus.synced.index);
    }
  }

  Future<void> _pushReturns(SupabaseClient client) async {
    // Pousse intégralement tous les retours locaux.
    for (final r in _returnBox.getAll()) {
      await client
          .from('returns')
          .upsert(_returnToMap(r), onConflict: 'id');
      await _pushReturnItems(client, r);
      await _recordMapping('return', _remoteId(r.id), r.id);
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

  Map<String, dynamic> _paymentToMap(PaymentEntity payment) {
    return {
      'id': _remoteId(payment.id),
      'amount': payment.amount,
      'method': payment.method,
      'sale_id': _remoteId(payment.saleId),
      'invoice_id': _remoteId(payment.invoiceId),
      'reference': payment.reference,
      'paid_at': payment.paidAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
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

  /// Tire toutes les tables distantes vers ObjectBox, dans l'ordre des
  /// dépendances (parents avant enfants) afin que les clés étrangères soient
  /// traduites via le mapping [SyncIdEntity].
  ///
  /// Chaque ligne distante est fusionnée sur la ligne locale correspondante
  /// (mapping ou espace d'ID de cet appareil) ; les lignes issues d'autres
  /// appareils sont créées localement avec de nouveaux ID et mappées. Les lignes
  /// enfants (items) sont remplacées en bloc pour refléter exactement l'état
  /// distant, comme le fait le push.
  Future<void> _pullAll() async {
    final client = Supabase.instance.client;
    await _pullCategories(client);
    await _pullProducts(client);
    await _pullCustomers(client);
    await _pullSales(client);
    await _pullInvoices(client);
    await _pullReturns(client);
    await _pullSaleItems(client);
    await _pullInvoiceItems(client);
    await _pullReturnItems(client);
    await _pullPayments(client);
  }

  Future<void> _pullCategories(SupabaseClient client) async {
    final rows = await client.from('categories').select();
    // Premier passage : insérer/mettre à jour chaque catégorie et garantir le
    // mapping. Second passage : résoudre parent_id une fois tous les mappings
    // connus (indépendant de l'ordre des lignes renvoyées par Supabase).
    for (final row in rows) {
      await _ensureMapped(
        'category',
        _categoryBox,
        row['id'] as int,
        (localId) => _categoryFromMap(row, localId),
      );
    }
    for (final row in rows) {
      final localId = _mappedLocalId('category', row['id'] as int);
      if (localId == null) continue;
      final existing = _categoryBox.get(localId);
      if (existing == null) continue;
      final parentId =
          _translateFk('category', row['parent_id'] as int? ?? 0);
      if (existing.parentId != parentId) {
        existing.parentId = parentId;
        _categoryBox.put(existing);
      }
    }
  }

  Future<void> _pullProducts(SupabaseClient client) async {
    final rows = await client.from('products').select();
    for (final row in rows) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('product', remoteId);

      // Fusion par SKU : un produit au même SKU déjà présent localement
      // (créé sur cet appareil ou tiré avant) est réutilisé au lieu de créer
      // un doublon.
      if (localId == null) {
        final sku = row['sku'] as String? ?? '';
        if (sku.isNotEmpty) {
          final existing = _productBox
              .query(ProductEntity_.sku.equals(sku, caseSensitive: false))
              .build()
              .findFirst();
          if (existing != null) localId = existing.id;
        }
      }
      if (localId == null && _isOwnRemoteId(remoteId)) {
        localId = _localFromRemoteId(remoteId);
      }

      final existing = localId != null ? _productBox.get(localId) : null;
      final resolvedLocalId = _productBox.put(
        _productFromMap(row, existing != null ? existing.id : 0),
      );
      await _recordMapping('product', remoteId, resolvedLocalId);
    }
  }

  Future<void> _pullCustomers(SupabaseClient client) async {
    final rows = await client.from('customers').select();
    for (final row in rows) {
      await _ensureMapped(
        'customer',
        _customerBox,
        row['id'] as int,
        (localId) => _customerFromMap(row, localId),
      );
    }
  }

  Future<void> _pullSales(SupabaseClient client) async {
    final rows = await client.from('sales').select();
    for (final row in rows) {
      await _ensureMapped(
        'sale',
        _saleBox,
        row['id'] as int,
        (localId) => _saleFromMap(row, localId),
      );
    }
  }

  Future<void> _pullInvoices(SupabaseClient client) async {
    final rows = await client.from('invoices').select();
    for (final row in rows) {
      await _ensureMapped(
        'invoice',
        _invoiceBox,
        row['id'] as int,
        (localId) => _invoiceFromMap(row, localId),
      );
    }
  }

  Future<void> _pullReturns(SupabaseClient client) async {
    final rows = await client.from('returns').select();
    for (final row in rows) {
      await _ensureMapped(
        'return',
        _returnBox,
        row['id'] as int,
        (localId) => _returnFromMap(row, localId),
      );
    }
  }

  /// Remplace les lignes de vente locales de chaque vente distante, comme le
  /// fait le push (delete + insert). Les lignes sont groupées par vente et
  /// traduites sur l'ID local de la vente via le mapping.
  Future<void> _pullSaleItems(SupabaseClient client) async {
    final rows = await client.from('sale_items').select();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final saleRemoteId = row['sale_id'] as int? ?? 0;
      if (saleRemoteId <= 0) continue;
      grouped.putIfAbsent(saleRemoteId, () => []).add(row);
    }
    final itemBox = ObjectboxDatabase.box<SaleItemEntity>();
    for (final entry in grouped.entries) {
      final localSaleId = _translateFk('sale', entry.key);
      if (localSaleId <= 0) continue;
      itemBox
          .query(SaleItemEntity_.saleId.equals(localSaleId))
          .build()
          .remove();
      itemBox.putMany(
        entry.value.map((row) => _saleItemFromMap(row)).toList(),
      );
    }
  }

  Future<void> _pullInvoiceItems(SupabaseClient client) async {
    final rows = await client.from('invoice_items').select();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final invoiceRemoteId = row['invoice_id'] as int? ?? 0;
      if (invoiceRemoteId <= 0) continue;
      grouped.putIfAbsent(invoiceRemoteId, () => []).add(row);
    }
    final itemBox = ObjectboxDatabase.box<InvoiceItemEntity>();
    for (final entry in grouped.entries) {
      final localInvoiceId = _translateFk('invoice', entry.key);
      if (localInvoiceId <= 0) continue;
      itemBox
          .query(InvoiceItemEntity_.invoiceId.equals(localInvoiceId))
          .build()
          .remove();
      itemBox.putMany(
        entry.value.map((row) => _invoiceItemFromMap(row)).toList(),
      );
    }
  }

  Future<void> _pullReturnItems(SupabaseClient client) async {
    final rows = await client.from('return_items').select();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final returnRemoteId = row['return_id'] as int? ?? 0;
      if (returnRemoteId <= 0) continue;
      grouped.putIfAbsent(returnRemoteId, () => []).add(row);
    }
    final itemBox = ObjectboxDatabase.box<ReturnItemEntity>();
    for (final entry in grouped.entries) {
      final localReturnId = _translateFk('return', entry.key);
      if (localReturnId <= 0) continue;
      itemBox
          .query(ReturnItemEntity_.returnId.equals(localReturnId))
          .build()
          .remove();
      itemBox.putMany(
        entry.value.map((row) => _returnItemFromMap(row)).toList(),
      );
    }
  }

  Future<void> _pullPayments(SupabaseClient client) async {
    final rows = await client.from('payments').select();
    for (final row in rows) {
      await _ensureMapped(
        'payment',
        _paymentBox,
        row['id'] as int,
        (localId) => _paymentFromMap(row, localId),
      );
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

  ProductEntity _productFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return ProductEntity()
      ..id = localId
      ..sku = row['sku'] as String? ?? ''
      ..name = row['name'] as String? ?? ''
      ..description = row['description'] as String?
      ..categoryId = _translateFk('category', row['category_id'] as int? ?? 0)
      ..price = (row['price'] as num?)?.toDouble() ?? 0
      ..costPrice = (row['cost_price'] as num?)?.toDouble() ?? 0
      ..taxRate =
          (row['tax_rate'] as num?)?.toDouble() ?? AppConstants.defaultTaxRate
      ..stock = (row['stock'] as num?)?.toDouble() ?? 0
      ..lowStockThreshold =
          (row['low_stock_threshold'] as num?)?.toDouble() ?? 5
      ..barcode = row['barcode'] as String?
      ..imageUrl = row['image_url'] as String?
      ..isActive = row['is_active'] as bool? ?? true
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  CategoryEntity _categoryFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return CategoryEntity()
      ..id = localId
      ..name = row['name'] as String? ?? ''
      ..parentId = 0
      ..sortOrder = row['sort_order'] as int? ?? 0
      ..isActive = row['is_active'] as bool? ?? true
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  CustomerEntity _customerFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return CustomerEntity()
      ..id = localId
      ..name = row['name'] as String? ?? ''
      ..phone = row['phone'] as String?
      ..email = row['email'] as String?
      ..address = row['address'] as String?
      ..company = row['company'] as String?
      ..taxId = row['tax_id'] as String?
      ..notes = row['notes'] as String?
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  SaleEntity _saleFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return SaleEntity()
      ..id = localId
      ..saleNumber = row['sale_number'] as String? ?? ''
      ..customerId = _translateFk('customer', row['customer_id'] as int? ?? 0)
      ..cashierId = row['cashier_id'] as int? ?? 0
      ..paymentMethod = row['payment_method'] as int? ?? 0
      ..status = row['status'] as int? ?? 0
      ..discountTotal = (row['discount_total'] as num?)?.toDouble() ?? 0
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  InvoiceEntity _invoiceFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return InvoiceEntity()
      ..id = localId
      ..invoiceNumber = row['invoice_number'] as String? ?? ''
      ..saleId = _translateFk('sale', row['sale_id'] as int? ?? 0)
      ..customerId = _translateFk('customer', row['customer_id'] as int? ?? 0)
      ..status = row['status'] as int? ?? 0
      ..discountTotal = (row['discount_total'] as num?)?.toDouble() ?? 0
      ..companyName = row['company_name'] as String?
      ..companyAddress = row['company_address'] as String?
      ..companyTaxId = row['company_tax_id'] as String?
      ..dueDate = DateTime.tryParse(row['due_date'] as String? ?? '')
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  ReturnRecordEntity _returnFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return ReturnRecordEntity()
      ..id = localId
      ..saleId = _translateFk('sale', row['sale_id'] as int? ?? 0)
      ..saleNumber = row['sale_number'] as String? ?? ''
      ..customerId = _translateFk('customer', row['customer_id'] as int? ?? 0)
      ..reason = row['reason'] as String?
      ..createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? now
      ..updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  SaleItemEntity _saleItemFromMap(Map<String, dynamic> row) {
    return SaleItemEntity()
      ..saleId = _translateFk('sale', row['sale_id'] as int? ?? 0)
      ..productId = _translateFk('product', row['product_id'] as int? ?? 0)
      ..productName = row['product_name'] as String? ?? ''
      ..sku = row['sku'] as String? ?? ''
      ..unitPrice = (row['unit_price'] as num?)?.toDouble() ?? 0
      ..costPrice = (row['cost_price'] as num?)?.toDouble() ?? 0
      ..taxRate = (row['tax_rate'] as num?)?.toDouble() ?? 0
      ..quantity = (row['quantity'] as num?)?.toDouble() ?? 0
      ..discount = (row['discount'] as num?)?.toDouble() ?? 0;
  }

  InvoiceItemEntity _invoiceItemFromMap(Map<String, dynamic> row) {
    return InvoiceItemEntity()
      ..invoiceId = _translateFk('invoice', row['invoice_id'] as int? ?? 0)
      ..productId = _translateFk('product', row['product_id'] as int? ?? 0)
      ..description = row['description'] as String? ?? ''
      ..unitPrice = (row['unit_price'] as num?)?.toDouble() ?? 0
      ..quantity = (row['quantity'] as num?)?.toDouble() ?? 0
      ..taxRate = (row['tax_rate'] as num?)?.toDouble() ?? 0
      ..discount = (row['discount'] as num?)?.toDouble() ?? 0;
  }

  ReturnItemEntity _returnItemFromMap(Map<String, dynamic> row) {
    return ReturnItemEntity()
      ..returnId = _translateFk('return', row['return_id'] as int? ?? 0)
      ..productId = _translateFk('product', row['product_id'] as int? ?? 0)
      ..description = row['description'] as String? ?? ''
      ..unitPrice = (row['unit_price'] as num?)?.toDouble() ?? 0
      ..quantity = (row['quantity'] as num?)?.toDouble() ?? 0
      ..taxRate = (row['tax_rate'] as num?)?.toDouble() ?? 0
      ..discount = (row['discount'] as num?)?.toDouble() ?? 0;
  }

  PaymentEntity _paymentFromMap(Map<String, dynamic> row, int localId) {
    final now = DateTime.now();
    return PaymentEntity()
      ..id = localId
      ..amount = (row['amount'] as num?)?.toDouble() ?? 0
      ..method = row['method'] as int? ?? 0
      ..saleId = _translateFk('sale', row['sale_id'] as int? ?? 0)
      ..invoiceId = _translateFk('invoice', row['invoice_id'] as int? ?? 0)
      ..reference = row['reference'] as String?
      ..paidAt = DateTime.tryParse(row['paid_at'] as String? ?? '') ?? now
      ..syncStatus = SyncStatus.synced.index;
  }

  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    _onlineController.close();
  }
}
