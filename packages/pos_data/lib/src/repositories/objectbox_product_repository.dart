import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/product_entity.dart';
import '../utils/recent_sort.dart';
import '../../objectbox.g.dart';

class ObjectboxProductRepository implements ProductRepository {
  ObjectboxProductRepository()
      : _box = ObjectboxDatabase.box<ProductEntity>();

  final Box<ProductEntity> _box;

  @override
  Stream<List<Product>> watchAll() {
    return _box
        .query(ProductEntity_.isActive.equals(true))
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toDomain).sortedByRecent(
              id: (e) => e.id,
              createdAt: (e) => e.createdAt,
              updatedAt: (e) => e.updatedAt,
            ).toList());
  }

  @override
  Stream<List<Product>> watchLowStock() {
    return _box
        .query(ProductEntity_.isActive.equals(true))
        .watch(triggerImmediately: true)
        .map(
          (query) => query
              .find()
              .where((e) => e.stock <= e.lowStockThreshold)
              .map(_toDomain)
              .sortedByRecent(
              id: (e) => e.id,
              createdAt: (e) => e.createdAt,
              updatedAt: (e) => e.updatedAt,
            )
              .toList(),
        );
  }

  @override
  Future<List<Product>> getAll() async {
    return _box
        .query(ProductEntity_.isActive.equals(true))
        .build()
        .find()
        .map(_toDomain)
        .sortedByRecent(
              id: (e) => e.id,
              createdAt: (e) => e.createdAt,
              updatedAt: (e) => e.updatedAt,
            )
        .toList();
  }

  @override
  Future<Product?> getById(int id) async {
    final entity = _box.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<Product?> getBySku(String sku) async {
    final entity = _box
        .query(ProductEntity_.sku.equals(sku, caseSensitive: false))
        .build()
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<List<Product>> search(String query) async {
    final q = query.trim().toLowerCase();
    final products = _box
        .query(ProductEntity_.isActive.equals(true))
        .build()
        .find()
        .map(_toDomain)
        .where((p) => p.matchesQuery(q))
        .sortedByRecent(
              id: (e) => e.id,
              createdAt: (e) => e.createdAt,
              updatedAt: (e) => e.updatedAt,
            )
        .toList();
    return products;
  }

  @override
  Future<int> save(Product product) async {
    final entity = _toEntity(product);
    return _box.put(entity);
  }

  @override
  Future<void> saveMany(List<Product> products) async {
    _box.putMany(products.map(_toEntity).toList());
  }

  @override
  Future<void> delete(int id) async {
    final entity = _box.get(id);
    if (entity == null) return;
    entity.isActive = false;
    entity.syncStatus = SyncStatus.pending.index;
    _box.put(entity);
  }

  Product _toDomain(ProductEntity e) {
    return Product(
      id: e.id,
      sku: e.sku,
      name: e.name,
      description: e.description,
      categoryId: e.categoryId == 0 ? null : e.categoryId,
      price: e.price,
      costPrice: e.costPrice,
      taxRate: e.taxRate,
      stock: e.stock,
      lowStockThreshold: e.lowStockThreshold,
      barcode: e.barcode,
      imageUrl: e.imageUrl,
      isActive: e.isActive,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  ProductEntity _toEntity(Product p) {
    final entity = ProductEntity()
      ..id = p.id
      ..sku = p.sku
      ..name = p.name
      ..description = p.description
      ..categoryId = p.categoryId ?? 0
      ..price = p.price
      ..costPrice = p.costPrice
      ..taxRate = p.taxRate
      ..stock = p.stock
      ..lowStockThreshold = p.lowStockThreshold
      ..barcode = p.barcode
      ..imageUrl = p.imageUrl
      ..isActive = p.isActive
      ..createdAt = p.createdAt ?? DateTime.now()
      ..updatedAt = p.updatedAt ?? DateTime.now()
      ..syncStatus = p.syncStatus.index;
    return entity;
  }
}

SyncStatus _toSyncStatus(int index) {
  if (index < 0 || index >= SyncStatus.values.length) {
    return SyncStatus.synced;
  }
  return SyncStatus.values[index];
}
