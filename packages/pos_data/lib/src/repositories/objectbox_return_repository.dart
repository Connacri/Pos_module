import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/return_item_entity.dart';
import '../models/objectbox/return_record_entity.dart';
import '../utils/recent_sort.dart';
import '../../objectbox.g.dart';

class ObjectboxReturnRepository implements ReturnRepository {
  ObjectboxReturnRepository()
      : _box = ObjectboxDatabase.box<ReturnRecordEntity>(),
        _itemsBox = ObjectboxDatabase.box<ReturnItemEntity>();

  final Box<ReturnRecordEntity> _box;
  final Box<ReturnItemEntity> _itemsBox;

  @override
  Stream<List<ReturnRecord>> watchAll() {
    return _box
        .query()
        .watch(triggerImmediately: true)
        .map(
          (query) => query.find().map(_toDomain).sortedByRecent(
                id: (e) => e.id,
                createdAt: (e) => e.createdAt,
                updatedAt: (e) => e.updatedAt,
              ).toList(),
        );
  }

  @override
  Future<List<ReturnRecord>> getAll() async {
    return _box
        .query()
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
  Future<List<ReturnRecord>> getBySale(int saleId) async {
    return _box
        .query(ReturnRecordEntity_.saleId.equals(saleId))
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
  Future<int> save(ReturnRecord record) async {
    final entity = _toEntity(record);
    final id = _box.put(entity);

    _itemsBox.query(ReturnItemEntity_.returnId.equals(id)).build().remove();
    for (final item in record.items) {
      _itemsBox.put(_toItemEntity(item, id));
    }
    return id;
  }

  @override
  Future<void> delete(int id) async {
    _itemsBox.query(ReturnItemEntity_.returnId.equals(id)).build().remove();
    _box.remove(id);
  }

  @override
  Future<int> count() async => _box.count();

  ReturnRecord _toDomain(ReturnRecordEntity e) {
    final items = _itemsBox
        .query(ReturnItemEntity_.returnId.equals(e.id))
        .build()
        .find()
        .map(_toReturnItem)
        .toList();
    return ReturnRecord(
      id: e.id,
      saleId: e.saleId,
      saleNumber: e.saleNumber.isEmpty ? null : e.saleNumber,
      customerId: e.customerId == 0 ? null : e.customerId,
      items: items,
      reason: e.reason,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  ReturnRecordEntity _toEntity(ReturnRecord r) {
    return ReturnRecordEntity()
      ..id = r.id
      ..saleId = r.saleId
      ..saleNumber = r.saleNumber ?? ''
      ..customerId = r.customerId ?? 0
      ..reason = r.reason
      ..createdAt = r.createdAt ?? DateTime.now()
      ..updatedAt = r.updatedAt ?? DateTime.now()
      ..syncStatus = r.syncStatus.index;
  }

  ReturnItem _toReturnItem(ReturnItemEntity e) {
    return ReturnItem(
      productId: e.productId,
      description: e.description,
      unitPrice: e.unitPrice,
      quantity: e.quantity,
      taxRate: e.taxRate,
      discount: e.discount,
    );
  }

  ReturnItemEntity _toItemEntity(ReturnItem item, int returnId) {
    return ReturnItemEntity()
      ..returnId = returnId
      ..productId = item.productId
      ..description = item.description
      ..unitPrice = item.unitPrice
      ..quantity = item.quantity
      ..taxRate = item.taxRate
      ..discount = item.discount;
  }
}

SyncStatus _toSyncStatus(int index) {
  if (index < 0 || index >= SyncStatus.values.length) {
    return SyncStatus.synced;
  }
  return SyncStatus.values[index];
}