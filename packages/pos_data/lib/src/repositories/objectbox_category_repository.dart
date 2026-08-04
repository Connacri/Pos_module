import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/category_entity.dart';
import '../../objectbox.g.dart';

class ObjectboxCategoryRepository implements CategoryRepository {
  ObjectboxCategoryRepository()
      : _box = ObjectboxDatabase.box<CategoryEntity>();

  final Box<CategoryEntity> _box;

  @override
  Stream<List<Category>> watchAll() {
    return _box
        .query(CategoryEntity_.isActive.equals(true))
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toDomain).toList());
  }

  @override
  Future<List<Category>> getAll() async {
    return _box
        .query(CategoryEntity_.isActive.equals(true))
        .build()
        .find()
        .map(_toDomain)
        .toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final entity = _box.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<int> save(Category category) async {
    final entity = _toEntity(category);
    return _box.put(entity);
  }

  @override
  Future<void> delete(int id) async {
    final entity = _box.get(id);
    if (entity == null) return;
    entity.isActive = false;
    entity.syncStatus = SyncStatus.pending.index;
    _box.put(entity);
  }

  Category _toDomain(CategoryEntity e) {
    return Category(
      id: e.id,
      name: e.name,
      parentId: e.parentId == 0 ? null : e.parentId,
      sortOrder: e.sortOrder,
      isActive: e.isActive,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  CategoryEntity _toEntity(Category c) {
    return CategoryEntity()
      ..id = c.id
      ..name = c.name
      ..parentId = c.parentId ?? 0
      ..sortOrder = c.sortOrder
      ..isActive = c.isActive
      ..createdAt = c.createdAt ?? DateTime.now()
      ..updatedAt = c.updatedAt ?? DateTime.now()
      ..syncStatus = c.syncStatus.index;
  }
}

SyncStatus _toSyncStatus(int index) {
  if (index < 0 || index >= SyncStatus.values.length) {
    return SyncStatus.synced;
  }
  return SyncStatus.values[index];
}
