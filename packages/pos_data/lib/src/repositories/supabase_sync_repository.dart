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
import '../models/objectbox/invoice_item_entity.dart';
import '../models/objectbox/payment_entity.dart';
import '../models/objectbox/product_entity.dart';
import '../models/objectbox/return_item_entity.dart';
import '../models/objectbox/return_record_entity.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import '../models/objectbox/sync_id_entity.dart';
import '../../objectbox.g.dart';

/// Synchronisation Supabase convergente et incrémentale.
///
/// L'ID distant n'est plus calculé localement (deviceId * 10^6 + idLocal) : il
/// est toujours l'ID canonique attribué par Supabase. Chaque enregistrement
/// local est relié à sa ligne distante par le mapping [SyncIdEntity], et les
/// enregistrements non encore mappés sont fusionnés par clé métier
/// (SKU, sale_number, invoice_number, nom+téléphone, référence, ...) au lieu
/// d'être dupliqués. Le push ne concerne que les lignes locales marquées
/// `pending` (ou toutes les lignes quand une table distante est vide, pour
/// rebooter après une remise à zéro). Le pull déduplique les lignes distantes
/// par clé métier et applique la règle « dernière modification gagne ».
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

  /// ID local mappé à [remoteId] pour [entityType], ou null si inconnu.
  int? _mappedLocalId(String entityType, int remoteId) {
    if (remoteId <= 0) return null;
    final m = _syncIdBox
        .query(SyncIdEntity_.entityType.equals(entityType)
            .and(SyncIdEntity_.remoteId.equals(remoteId)))
        .build()
        .findFirst();
    return m?.localId;
  }

  /// ID distant mappé à [localId] pour [entityType], ou null si inconnu.
  int? _mappedRemoteId(String entityType, int localId) {
    if (localId <= 0) return null;
    final m = _syncIdBox
        .query(SyncIdEntity_.entityType.equals(entityType)
            .and(SyncIdEntity_.localId.equals(localId)))
        .build()
        .findFirst();
    return m?.remoteId;
  }

  /// Traduit une clé étrangère distante en ID local ObjectBox via le mapping.
  int _translateFk(String entityType, int remoteFk) {
    return _mappedLocalId(entityType, remoteFk) ?? 0;
  }

  /// Enregistre la correspondance [remoteId] ↔ [localId] pour [entityType].
  ///
  /// Si la ligne locale est déjà mappée (mapping déplacé après une remise à
  /// zéro du serveur), le nouvel ID distant remplace l'ancien.
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
    await _pushAll();
    await _pullAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.keyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
    AppLogger.info('Synchronisation terminée');
  }

  // ---------------------------------------------------------------------------
  // Aides de requête Supabase
  // ---------------------------------------------------------------------------

  /// Renvoie la première ligne de [table] filtrée par [filter], ou null.
  Future<Map<String, dynamic>?> _findOne(
    SupabaseClient client,
    String table,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    ) filter,
  ) async {
    final rows = await filter(client.from(table).select()).limit(1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Renvoie la ligne [id] de [table], ou null si elle n'existe pas.
  Future<Map<String, dynamic>?> _findOneById(
    SupabaseClient client,
    String table,
    int id,
  ) async {
    if (id <= 0) return null;
    final rows = await client.from(table).select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Vrai si la table distante [table] ne contient aucune ligne.
  Future<bool> _remoteTableEmpty(SupabaseClient client, String table) async {
    final rows = await client.from(table).select('id').limit(1);
    return rows.isEmpty;
  }

  /// Horodatage « récence » d'une ligne distante (updated_at, sinon paid_at,
  /// sinon created_at) utilisé pour départager des doublons.
  DateTime? _rowTimestamp(Map<String, dynamic> row) {
    return DateTime.tryParse(
      '${row['updated_at'] ?? row['paid_at'] ?? row['created_at']}',
    );
  }

  bool _rowNewer(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = _rowTimestamp(a);
    final tb = _rowTimestamp(b);
    if (ta == null || tb == null) return false;
    return ta.isAfter(tb);
  }

  /// Vrai si la ligne locale non synchronisée (pending) est plus récente que
  /// la ligne distante : dans ce cas le pull ne doit pas l'écraser.
  bool _localIsNewerPending(
    DateTime localUpdated,
    int localSyncStatus,
    Map<String, dynamic> remoteRow,
  ) {
    if (localSyncStatus != SyncStatus.pending.index) return false;
    final remoteUpdated = _rowTimestamp(remoteRow);
    return remoteUpdated == null || localUpdated.isAfter(remoteUpdated);
  }

  // ---------------------------------------------------------------------------
  // Push : incrémental (pending) + fusion par clé métier
  // ---------------------------------------------------------------------------

  /// Pousse les modifications locales vers Supabase.
  ///
  /// Seules les lignes `pending` (créées ou modifiées hors-ligne) sont poussées,
  /// sauf si la table distante est vide : dans ce cas toutes les lignes locales
  /// sont poussées pour reconstruire le serveur après une remise à zéro.
  /// Chaque ligne est fusionnée sur son ID canonique (mapping existant, ligne
  /// distante retrouvée par clé métier, ou insertion nouvelle).
  Future<void> _pushAll() async {
    final client = Supabase.instance.client;
    await _pushCategories(client);
    await _pushProducts(client);
    await _pushCustomers(client);
    await _pushSales(client);
    await _pushInvoices(client);
    await _pushPayments(client);
    await _pushReturns(client);
  }

  /// Lignes locales à pousser pour une table : toutes si la table distante est
  /// vide (bootstrap), sinon uniquement celles en attente de synchronisation.
  Future<List<T>> _pushCandidates<T>(
    SupabaseClient client,
    String table,
    List<T> rows,
  ) async {
    if (rows.isEmpty) return const [];
    if (await _remoteTableEmpty(client, table)) return rows;
    return rows
        .where((r) => (r as dynamic).syncStatus != SyncStatus.synced.index)
        .toList();
  }

  /// Fusionne une ligne locale sur le serveur et renvoie son ID distant
  /// canonique.
  ///
  /// Résolution de l'ID canonique : mapping existant, puis ligne distante
  /// trouvée par clé métier ([finder]), puis insertion nouvelle (l'ID est alors
  /// attribué par le serveur). Si la ligne distante est plus récente que la
  /// ligne locale (updated_at), le serveur gagne et la ligne locale n'est pas
  /// écrasée (dernière modification gagne).
  Future<int> _pushRow({
    required SupabaseClient client,
    required String table,
    required String entityType,
    required int localId,
    required DateTime localUpdated,
    required Map<String, dynamic> Function() rowBuilder,
    required Future<Map<String, dynamic>?> Function()? finder,
  }) async {
    var remoteId = _mappedRemoteId(entityType, localId);
    Map<String, dynamic>? remoteRow;
    if (remoteId != null && remoteId > 0) {
      remoteRow = await _findOneById(client, table, remoteId);
    } else if (finder != null) {
      remoteRow = await finder();
    }

    if (remoteRow == null) {
      Map<String, dynamic> row;
      try {
        row = await client
            .from(table)
            .insert(rowBuilder())
            .select('id')
            .single();
      } on PostgrestException catch (e) {
        // Conflit 23505 (clé métier unique) survenu pendant l'insertion : la
        // ligne a été créée entre-temps par un autre appareil → fusionner.
        if (e.code != '23505' || finder == null) rethrow;
        final recovered = await finder();
        if (recovered == null) rethrow;
        remoteId = recovered['id'] as int;
        await client
            .from(table)
            .upsert({...rowBuilder(), 'id': remoteId}, onConflict: 'id');
        await _recordMapping(entityType, remoteId, localId);
        return remoteId;
      }
      remoteId = row['id'] as int;
      await _recordMapping(entityType, remoteId, localId);
      return remoteId;
    }

    remoteId = remoteRow['id'] as int;
    final remoteUpdated =
        DateTime.tryParse('${remoteRow['updated_at']}');
    if (remoteUpdated != null && remoteUpdated.isAfter(localUpdated)) {
      await _recordMapping(entityType, remoteId, localId);
      return remoteId;
    }
    await client
        .from(table)
        .upsert({...rowBuilder(), 'id': remoteId}, onConflict: 'id');
    await _recordMapping(entityType, remoteId, localId);
    return remoteId;
  }

  /// Pousse une ligne portant un numéro unique (sale_number / invoice_number).
  ///
  /// Un numéro déjà présent sur le serveur correspond soit à une copie tirée
  /// d'un autre appareil (même created_at → fusion), soit à une vente/facture
  /// réellement nouvelle d'un autre appareil (created_at différent → nouveau
  /// numéro via [_nextRemoteNumber]). En cas de collision restante, le numéro
  /// est régénéré depuis le max distant et l'insertion est réessayée.
  Future<int> _pushNumberedRow({
    required SupabaseClient client,
    required String table,
    required String entityType,
    required int localId,
    required DateTime localUpdated,
    required String numberColumn,
    required Map<String, dynamic> Function() rowBuilder,
    required void Function(String number) applyNumber,
  }) async {
    final mappedId = _mappedRemoteId(entityType, localId);
    if (mappedId != null && mappedId > 0) {
      final existing = await _findOneById(client, table, mappedId);
      if (existing == null) {
        // Ligne supprimée sur le serveur : recréation avec un numéro libre.
        return _insertNumbered(
          client: client,
          table: table,
          entityType: entityType,
          localId: localId,
          numberColumn: numberColumn,
          rowBuilder: rowBuilder,
          applyNumber: applyNumber,
        );
      }
      final remoteUpdated =
          DateTime.tryParse('${existing['updated_at']}');
      if (remoteUpdated != null && remoteUpdated.isAfter(localUpdated)) {
        await _recordMapping(entityType, mappedId, localId);
        return mappedId;
      }
      await client
          .from(table)
          .upsert({...rowBuilder(), 'id': mappedId}, onConflict: 'id');
      await _recordMapping(entityType, mappedId, localId);
      return mappedId;
    }

    final row = rowBuilder();
    final number = '${row[numberColumn]}';
    final match =
        await _findOne(client, table, (q) => q.eq(numberColumn, number));
    if (match != null && _sameNumberedEntity(match, row)) {
      final remoteId = match['id'] as int;
      final remoteUpdated = DateTime.tryParse('${match['updated_at']}');
      if (remoteUpdated == null || !remoteUpdated.isAfter(localUpdated)) {
        await client
            .from(table)
            .upsert({...row, 'id': remoteId}, onConflict: 'id');
      }
      await _recordMapping(entityType, remoteId, localId);
      return remoteId;
    }

    return _insertNumbered(
      client: client,
      table: table,
      entityType: entityType,
      localId: localId,
      numberColumn: numberColumn,
      rowBuilder: rowBuilder,
      applyNumber: applyNumber,
    );
  }

  /// Vrai si la ligne distante [remoteRow] est la même vente/facture logique
  /// que [localRow] : numéro identique ET date de création quasi identique
  /// (une copie tirée d'un autre appareil garde sa created_at ; une vente
  /// réellement nouvelle porte une date fraîche et ne doit pas être fusionnée).
  bool _sameNumberedEntity(
    Map<String, dynamic> remoteRow,
    Map<String, dynamic> localRow,
  ) {
    final remoteCreated = DateTime.tryParse('${remoteRow['created_at']}');
    final localCreated = DateTime.tryParse('${localRow['created_at']}');
    if (remoteCreated == null || localCreated == null) return true;
    return localCreated.difference(remoteCreated).inMilliseconds.abs() <= 1000;
  }

  /// Insère une ligne numérotée en régénérant le numéro en cas de collision
  /// 23505. Renvoie l'ID distant attribué par le serveur.
  Future<int> _insertNumbered({
    required SupabaseClient client,
    required String table,
    required String entityType,
    required int localId,
    required String numberColumn,
    required Map<String, dynamic> Function() rowBuilder,
    required void Function(String number) applyNumber,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final inserted =
            await client.from(table).insert(rowBuilder()).select('id').single();
        final remoteId = inserted['id'] as int;
        await _recordMapping(entityType, remoteId, localId);
        return remoteId;
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        if (attempt == maxAttempts - 1) rethrow;
        applyNumber(await _nextRemoteNumber(client, table, numberColumn));
      }
    }
    throw StateError('Insertion numérotée impossible');
  }

  /// Prochain numéro distant (max + 1) pour une colonne à numéro unique.
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

  /// Résout l'ID distant canonique d'un parent référencé par une clé étrangère.
  ///
  /// Si le parent local n'est pas encore mappé, il est poussé à la volée pour
  /// garantir l'intégrité des clés étrangères (parents avant enfants).
  Future<int> _resolveRemoteParent(
    SupabaseClient client,
    String entityType,
    String table,
    int localParentId,
  ) async {
    if (localParentId <= 0) return 0;
    final mapped = _mappedRemoteId(entityType, localParentId);
    if (mapped != null) return mapped;
    switch (entityType) {
      case 'category':
        final c = _categoryBox.get(localParentId);
        return c == null ? 0 : _pushCategory(client, c);
      case 'product':
        final p = _productBox.get(localParentId);
        return p == null ? 0 : _pushProduct(client, p);
      case 'customer':
        final c = _customerBox.get(localParentId);
        return c == null ? 0 : _pushCustomer(client, c);
      case 'sale':
        final s = _saleBox.get(localParentId);
        return s == null ? 0 : _pushSale(client, s);
      case 'invoice':
        final i = _invoiceBox.get(localParentId);
        return i == null ? 0 : _pushInvoice(client, i);
    }
    return 0;
  }

  Future<void> _pushCategories(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'categories', _categoryBox.getAll());
    for (final c in candidates) {
      await _pushCategory(client, c);
    }
    // Second passage : parent_id, une fois tous les parents mappés.
    for (final c in candidates) {
      if (c.parentId <= 0) continue;
      final remoteId = _mappedRemoteId('category', c.id);
      if (remoteId == null) continue;
      final parentRemoteId = await _resolveRemoteParent(
        client,
        'category',
        'categories',
        c.parentId,
      );
      if (parentRemoteId <= 0) continue;
      await client
          .from('categories')
          .update({'parent_id': parentRemoteId}).eq('id', remoteId);
    }
  }

  Future<int> _pushCategory(SupabaseClient client, CategoryEntity c) async {
    final remoteId = await _pushRow(
      client: client,
      table: 'categories',
      entityType: 'category',
      localId: c.id,
      localUpdated: c.updatedAt,
      rowBuilder: () => _categoryToMap(c),
      finder: () => c.name.trim().isEmpty
          ? Future.value(null)
          : _findOne(
              client,
              'categories',
              (q) => q.ilike('name', c.name.trim()),
            ),
    );
    _categoryBox.put(c..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<void> _pushProducts(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'products', _productBox.getAll());
    for (final p in candidates) {
      await _pushProduct(client, p);
    }
  }

  Future<int> _pushProduct(SupabaseClient client, ProductEntity p) async {
    final categoryRemoteId = await _resolveRemoteParent(
      client,
      'category',
      'categories',
      p.categoryId,
    );
    final remoteId = await _pushRow(
      client: client,
      table: 'products',
      entityType: 'product',
      localId: p.id,
      localUpdated: p.updatedAt,
      rowBuilder: () => _productToMap(p, categoryRemoteId: categoryRemoteId),
      finder: () => p.sku.trim().isEmpty
          ? Future.value(null)
          : _findOne(client, 'products', (q) => q.eq('sku', p.sku)),
    );
    _productBox.put(p..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<void> _pushCustomers(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'customers', _customerBox.getAll());
    for (final c in candidates) {
      await _pushCustomer(client, c);
    }
  }

  Future<int> _pushCustomer(SupabaseClient client, CustomerEntity c) async {
    final remoteId = await _pushRow(
      client: client,
      table: 'customers',
      entityType: 'customer',
      localId: c.id,
      localUpdated: c.updatedAt,
      rowBuilder: () => _customerToMap(c),
      finder: () => _findCustomer(client, c),
    );
    _customerBox.put(c..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<Map<String, dynamic>?> _findCustomer(
    SupabaseClient client,
    CustomerEntity c,
  ) async {
    final name = c.name.trim();
    if (name.isEmpty) return null;
    final phone = c.phone?.trim();
    return _findOne(client, 'customers', (q) {
      var query = q.ilike('name', name);
      if (phone != null && phone.isNotEmpty) query = query.eq('phone', phone);
      return query;
    });
  }

  Future<void> _pushSales(SupabaseClient client) async {
    final candidates = await _pushCandidates(client, 'sales', _saleBox.getAll());
    for (final s in candidates) {
      await _pushSale(client, s);
    }
  }

  Future<int> _pushSale(SupabaseClient client, SaleEntity s) async {
    final customerRemoteId = await _resolveRemoteParent(
      client,
      'customer',
      'customers',
      s.customerId,
    );
    final remoteId = await _pushNumberedRow(
      client: client,
      table: 'sales',
      entityType: 'sale',
      localId: s.id,
      localUpdated: s.updatedAt,
      numberColumn: 'sale_number',
      rowBuilder: () => _saleToMap(s, customerRemoteId: customerRemoteId),
      applyNumber: (number) {
        s.saleNumber = number;
        s.updatedAt = DateTime.now();
      },
    );
    await _pushSaleItems(client, s, remoteId);
    _saleBox.put(s..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<void> _pushSaleItems(
    SupabaseClient client,
    SaleEntity s,
    int saleRemoteId,
  ) async {
    final items = ObjectboxDatabase.box<SaleItemEntity>()
        .query(SaleItemEntity_.saleId.equals(s.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client.from('sale_items').delete().eq('sale_id', saleRemoteId);
      final maps = <Map<String, dynamic>>[];
      for (final item in items) {
        final productRemoteId = await _resolveRemoteParent(
          client,
          'product',
          'products',
          item.productId,
        );
        maps.add(_saleItemToMap(
          item,
          saleRemoteId: saleRemoteId,
          productRemoteId: productRemoteId,
        ));
      }
      await client.from('sale_items').insert(maps);
    } catch (e) {
      AppLogger.warning(
        'Échec synchronisation des lignes de la vente ${s.id}: $e',
      );
    }
  }

  Future<void> _pushInvoices(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'invoices', _invoiceBox.getAll());
    for (final i in candidates) {
      await _pushInvoice(client, i);
    }
  }

  Future<int> _pushInvoice(SupabaseClient client, InvoiceEntity i) async {
    final saleRemoteId =
        await _resolveRemoteParent(client, 'sale', 'sales', i.saleId);
    final customerRemoteId = await _resolveRemoteParent(
      client,
      'customer',
      'customers',
      i.customerId,
    );
    final remoteId = await _pushNumberedRow(
      client: client,
      table: 'invoices',
      entityType: 'invoice',
      localId: i.id,
      localUpdated: i.updatedAt,
      numberColumn: 'invoice_number',
      rowBuilder: () => _invoiceToMap(
        i,
        saleRemoteId: saleRemoteId,
        customerRemoteId: customerRemoteId,
      ),
      applyNumber: (number) {
        i.invoiceNumber = number;
        i.updatedAt = DateTime.now();
      },
    );
    await _pushInvoiceItems(client, i, remoteId);
    _invoiceBox.put(i..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<void> _pushInvoiceItems(
    SupabaseClient client,
    InvoiceEntity i,
    int invoiceRemoteId,
  ) async {
    final items = ObjectboxDatabase.box<InvoiceItemEntity>()
        .query(InvoiceItemEntity_.invoiceId.equals(i.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client
          .from('invoice_items')
          .delete()
          .eq('invoice_id', invoiceRemoteId);
      final maps = <Map<String, dynamic>>[];
      for (final item in items) {
        final productRemoteId = await _resolveRemoteParent(
          client,
          'product',
          'products',
          item.productId,
        );
        maps.add(_invoiceItemToMap(
          item,
          invoiceRemoteId: invoiceRemoteId,
          productRemoteId: productRemoteId,
        ));
      }
      await client.from('invoice_items').insert(maps);
    } catch (e) {
      AppLogger.warning(
        'Échec synchronisation des lignes de la facture ${i.id}: $e',
      );
    }
  }

  Future<void> _pushPayments(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'payments', _paymentBox.getAll());
    for (final p in candidates) {
      await _pushPayment(client, p);
    }
  }

  Future<int> _pushPayment(SupabaseClient client, PaymentEntity payment) async {
    final saleRemoteId = await _resolveRemoteParent(
      client,
      'sale',
      'sales',
      payment.saleId,
    );
    final invoiceRemoteId = await _resolveRemoteParent(
      client,
      'invoice',
      'invoices',
      payment.invoiceId,
    );
    final remoteId = await _pushRow(
      client: client,
      table: 'payments',
      entityType: 'payment',
      localId: payment.id,
      localUpdated: payment.paidAt,
      rowBuilder: () => _paymentToMap(
        payment,
        saleRemoteId: saleRemoteId,
        invoiceRemoteId: invoiceRemoteId,
      ),
      finder: () async {
        final reference = payment.reference?.trim();
        if (reference != null && reference.isNotEmpty) {
          return _findOne(
            client,
            'payments',
            (q) => q.eq('reference', reference),
          );
        }
        if (saleRemoteId > 0 || invoiceRemoteId > 0) {
          return _findOne(
            client,
            'payments',
            (q) {
              var query = q;
              if (saleRemoteId > 0) query = query.eq('sale_id', saleRemoteId);
              if (invoiceRemoteId > 0) {
                query = query.eq('invoice_id', invoiceRemoteId);
              }
              return query;
            },
          );
        }
        return null;
      },
    );
    _paymentBox.put(payment..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<void> _pushReturns(SupabaseClient client) async {
    final candidates =
        await _pushCandidates(client, 'returns', _returnBox.getAll());
    for (final r in candidates) {
      await _pushReturn(client, r);
    }
  }

  Future<int> _pushReturn(SupabaseClient client, ReturnRecordEntity r) async {
    final saleRemoteId =
        await _resolveRemoteParent(client, 'sale', 'sales', r.saleId);
    final customerRemoteId = await _resolveRemoteParent(
      client,
      'customer',
      'customers',
      r.customerId,
    );
    final remoteId = await _pushRow(
      client: client,
      table: 'returns',
      entityType: 'return',
      localId: r.id,
      localUpdated: r.updatedAt,
      rowBuilder: () => _returnToMap(
        r,
        saleRemoteId: saleRemoteId,
        customerRemoteId: customerRemoteId,
      ),
      finder: () => _findReturn(client, r),
    );
    await _pushReturnItems(client, r, remoteId);
    _returnBox.put(r..syncStatus = SyncStatus.synced.index);
    return remoteId;
  }

  Future<Map<String, dynamic>?> _findReturn(
    SupabaseClient client,
    ReturnRecordEntity r,
  ) async {
    final created = r.createdAt.toIso8601String();
    return _findOne(
      client,
      'returns',
      (q) => q
          .eq('sale_number', r.saleNumber)
          .eq('created_at', created),
    );
  }

  Future<void> _pushReturnItems(
    SupabaseClient client,
    ReturnRecordEntity r,
    int returnRemoteId,
  ) async {
    final items = ObjectboxDatabase.box<ReturnItemEntity>()
        .query(ReturnItemEntity_.returnId.equals(r.id))
        .build()
        .find();
    if (items.isEmpty) return;
    try {
      await client
          .from('return_items')
          .delete()
          .eq('return_id', returnRemoteId);
      final maps = <Map<String, dynamic>>[];
      for (final item in items) {
        final productRemoteId = await _resolveRemoteParent(
          client,
          'product',
          'products',
          item.productId,
        );
        maps.add(_returnItemToMap(
          item,
          returnRemoteId: returnRemoteId,
          productRemoteId: productRemoteId,
        ));
      }
      await client.from('return_items').insert(maps);
    } catch (e) {
      AppLogger.warning('Échec synchronisation des lignes du retour ${r.id}: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pull : dédup par clé métier + dernière modification gagne
  // ---------------------------------------------------------------------------

  /// Tire les tables distantes vers ObjectBox dans l'ordre des dépendances
  /// (parents avant enfants). Les lignes distantes sont dédupliquées par clé
  /// métier (on garde la plus récente), fusionnées sur la ligne locale
  /// correspondante (mapping, clé métier locale, ou nouvelle ligne) et les
  /// lignes enfants sont remplacées en bloc.
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
    final byName = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final name = (row['name'] as String? ?? '').trim().toLowerCase();
      if (name.isEmpty) continue;
      final existing = byName[name];
      if (existing == null || _rowNewer(row, existing)) byName[name] = row;
    }
    final deduped = byName.values.toList();
    for (final row in deduped) {
      await _pullCategoryRow(row);
    }
    // Second passage : résolution de parent_id une fois tous les mappings connus.
    for (final row in deduped) {
      final localId = _mappedLocalId('category', row['id'] as int);
      if (localId == null) continue;
      final existing = _categoryBox.get(localId);
      if (existing == null) continue;
      final parentId = _translateFk('category', row['parent_id'] as int? ?? 0);
      if (existing.parentId != parentId) {
        existing.parentId = parentId;
        _categoryBox.put(existing);
      }
    }
  }

  Future<void> _pullCategoryRow(Map<String, dynamic> row) async {
    final remoteId = row['id'] as int;
    var localId = _mappedLocalId('category', remoteId);
    if (localId == null) {
      final name = row['name'] as String? ?? '';
      if (name.isNotEmpty) {
        final existing = _categoryBox
            .query(CategoryEntity_.name.equals(name, caseSensitive: false))
            .build()
            .findFirst();
        if (existing != null) localId = existing.id;
      }
    }
    final local = localId != null ? _categoryBox.get(localId) : null;
    if (local != null &&
        _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
      return;
    }
    final resolved = _categoryBox.put(_categoryFromMap(row, local?.id ?? 0));
    await _recordMapping('category', remoteId, resolved);
  }

  Future<void> _pullProducts(SupabaseClient client) async {
    final rows = await client.from('products').select();
    final bySku = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final sku = (row['sku'] as String? ?? '').trim().toLowerCase();
      if (sku.isEmpty) continue;
      final existing = bySku[sku];
      if (existing == null || _rowNewer(row, existing)) bySku[sku] = row;
    }
    for (final row in bySku.values) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('product', remoteId);

      // Fusion par SKU : un produit au même SKU déjà présent localement est
      // réutilisé au lieu de créer un doublon.
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

      final local = localId != null ? _productBox.get(localId) : null;
      if (local != null &&
          _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
        continue;
      }
      final resolved =
          _productBox.put(_productFromMap(row, local?.id ?? 0));
      await _recordMapping('product', remoteId, resolved);
    }
  }

  Future<void> _pullCustomers(SupabaseClient client) async {
    final rows = await client.from('customers').select();
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key =
          '${(row['name'] as String? ?? '').trim().toLowerCase()}|${row['phone'] ?? ''}';
      if (key.startsWith('|') && key.length == 1) continue;
      final existing = byKey[key];
      if (existing == null || _rowNewer(row, existing)) byKey[key] = row;
    }
    for (final row in byKey.values) {
      await _pullCustomerRow(row);
    }
  }

  Future<void> _pullCustomerRow(Map<String, dynamic> row) async {
    final remoteId = row['id'] as int;
    var localId = _mappedLocalId('customer', remoteId);
    if (localId == null) {
      final name = (row['name'] as String? ?? '').trim();
      final phone = row['phone'] as String?;
      if (name.isNotEmpty) {
        final candidates = _customerBox
            .query(CustomerEntity_.name.equals(name, caseSensitive: false))
            .build()
            .find();
        for (final c in candidates) {
          if ((c.phone ?? '') == (phone ?? '')) {
            localId = c.id;
            break;
          }
        }
      }
    }
    final local = localId != null ? _customerBox.get(localId) : null;
    if (local != null &&
        _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
      return;
    }
    final resolved = _customerBox.put(_customerFromMap(row, local?.id ?? 0));
    await _recordMapping('customer', remoteId, resolved);
  }

  Future<void> _pullSales(SupabaseClient client) async {
    final rows = await client.from('sales').select();
    final byNumber = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final number = (row['sale_number'] as String? ?? '').trim();
      if (number.isEmpty) continue;
      final existing = byNumber[number];
      if (existing == null || _rowNewer(row, existing)) byNumber[number] = row;
    }
    for (final row in byNumber.values) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('sale', remoteId);
      if (localId == null) {
        final number = row['sale_number'] as String? ?? '';
        if (number.isNotEmpty) {
          final existing = _saleBox
              .query(SaleEntity_.saleNumber.equals(number))
              .build()
              .findFirst();
          if (existing != null) localId = existing.id;
        }
      }
      final local = localId != null ? _saleBox.get(localId) : null;
      if (local != null &&
          _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
        continue;
      }
      final resolved = _saleBox.put(_saleFromMap(row, local?.id ?? 0));
      await _recordMapping('sale', remoteId, resolved);
    }
  }

  Future<void> _pullInvoices(SupabaseClient client) async {
    final rows = await client.from('invoices').select();
    final byNumber = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final number = (row['invoice_number'] as String? ?? '').trim();
      if (number.isEmpty) continue;
      final existing = byNumber[number];
      if (existing == null || _rowNewer(row, existing)) byNumber[number] = row;
    }
    for (final row in byNumber.values) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('invoice', remoteId);
      if (localId == null) {
        final number = row['invoice_number'] as String? ?? '';
        if (number.isNotEmpty) {
          final existing = _invoiceBox
              .query(InvoiceEntity_.invoiceNumber.equals(number))
              .build()
              .findFirst();
          if (existing != null) localId = existing.id;
        }
      }
      final local = localId != null ? _invoiceBox.get(localId) : null;
      if (local != null &&
          _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
        continue;
      }
      final resolved = _invoiceBox.put(_invoiceFromMap(row, local?.id ?? 0));
      await _recordMapping('invoice', remoteId, resolved);
    }
  }

  Future<void> _pullReturns(SupabaseClient client) async {
    final rows = await client.from('returns').select();
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key =
          '${row['sale_number']}|${row['reason']}|${row['created_at']}';
      final existing = byKey[key];
      if (existing == null || _rowNewer(row, existing)) byKey[key] = row;
    }
    for (final row in byKey.values) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('return', remoteId);
      if (localId == null) {
        final saleNumber = row['sale_number'] as String? ?? '';
        final reason = row['reason'] as String?;
        if (saleNumber.isNotEmpty) {
          final existing = _returnBox
              .query(ReturnRecordEntity_.saleNumber.equals(saleNumber))
              .build()
              .find();
          for (final r in existing) {
            if (r.reason == reason) {
              localId = r.id;
              break;
            }
          }
        }
      }
      final local = localId != null ? _returnBox.get(localId) : null;
      if (local != null &&
          _localIsNewerPending(local.updatedAt, local.syncStatus, row)) {
        continue;
      }
      final resolved = _returnBox.put(_returnFromMap(row, local?.id ?? 0));
      await _recordMapping('return', remoteId, resolved);
    }
  }

  /// Remplace les lignes de vente locales de chaque vente distante (delete +
  /// insert en bloc), groupées par ID distant de la vente.
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
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final reference = (row['reference'] as String? ?? '').trim();
      final key = reference.isNotEmpty
          ? 'ref|$reference'
          : 'sale${row['sale_id']}|inv${row['invoice_id']}|${row['method']}|${row['amount']}';
      final existing = byKey[key];
      if (existing == null || _rowNewer(row, existing)) byKey[key] = row;
    }
    for (final row in byKey.values) {
      final remoteId = row['id'] as int;
      var localId = _mappedLocalId('payment', remoteId);
      if (localId == null) {
        final reference = (row['reference'] as String? ?? '').trim();
        if (reference.isNotEmpty) {
          final existing = _paymentBox
              .query(PaymentEntity_.reference.equals(reference))
              .build()
              .findFirst();
          if (existing != null) localId = existing.id;
        }
      }
      final local = localId != null ? _paymentBox.get(localId) : null;
      if (local != null &&
          _localIsNewerPending(local.paidAt, local.syncStatus, row)) {
        continue;
      }
      final resolved = _paymentBox.put(_paymentFromMap(row, local?.id ?? 0));
      await _recordMapping('payment', remoteId, resolved);
    }
  }

  // ---------------------------------------------------------------------------
  // Construction des lignes distantes (sans 'id' : attribué par le serveur)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _productToMap(
    ProductEntity p, {
    required int categoryRemoteId,
  }) {
    return {
      'sku': p.sku,
      'name': p.name,
      'description': p.description,
      'category_id': categoryRemoteId,
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
      'name': c.name,
      'parent_id': 0,
      'sort_order': c.sortOrder,
      'is_active': c.isActive,
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _customerToMap(CustomerEntity c) {
    return {
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

  Map<String, dynamic> _saleToMap(
    SaleEntity s, {
    required int customerRemoteId,
  }) {
    return {
      'sale_number': s.saleNumber,
      'customer_id': customerRemoteId,
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

  Map<String, dynamic> _invoiceToMap(
    InvoiceEntity i, {
    required int saleRemoteId,
    required int customerRemoteId,
  }) {
    return {
      'invoice_number': i.invoiceNumber,
      'sale_id': saleRemoteId,
      'customer_id': customerRemoteId,
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

  Map<String, dynamic> _paymentToMap(
    PaymentEntity payment, {
    required int saleRemoteId,
    required int invoiceRemoteId,
  }) {
    return {
      'amount': payment.amount,
      'method': payment.method,
      'sale_id': saleRemoteId,
      'invoice_id': invoiceRemoteId,
      'reference': payment.reference,
      'paid_at': payment.paidAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _returnToMap(
    ReturnRecordEntity r, {
    required int saleRemoteId,
    required int customerRemoteId,
  }) {
    return {
      'sale_id': saleRemoteId,
      'sale_number': r.saleNumber,
      'customer_id': customerRemoteId,
      'reason': r.reason,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'sync_status': SyncStatus.synced.index,
    };
  }

  Map<String, dynamic> _saleItemToMap(
    SaleItemEntity item, {
    required int saleRemoteId,
    required int productRemoteId,
  }) {
    return {
      'sale_id': saleRemoteId,
      'product_id': productRemoteId,
      'product_name': item.productName,
      'sku': item.sku,
      'unit_price': item.unitPrice,
      'cost_price': item.costPrice,
      'tax_rate': item.taxRate,
      'quantity': item.quantity,
      'discount': item.discount,
    };
  }

  Map<String, dynamic> _invoiceItemToMap(
    InvoiceItemEntity item, {
    required int invoiceRemoteId,
    required int productRemoteId,
  }) {
    return {
      'invoice_id': invoiceRemoteId,
      'product_id': productRemoteId,
      'description': item.description,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'tax_rate': item.taxRate,
      'discount': item.discount,
    };
  }

  Map<String, dynamic> _returnItemToMap(
    ReturnItemEntity item, {
    required int returnRemoteId,
    required int productRemoteId,
  }) {
    return {
      'return_id': returnRemoteId,
      'product_id': productRemoteId,
      'description': item.description,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'tax_rate': item.taxRate,
      'discount': item.discount,
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

  // ---------------------------------------------------------------------------
  // Reconstruction des entités locales depuis les lignes distantes
  // ---------------------------------------------------------------------------

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
