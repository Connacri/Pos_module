import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/sale_entity.dart';
import '../models/objectbox/sale_item_entity.dart';
import '../../objectbox.g.dart';

class ObjectboxSaleRepository implements SaleRepository {
  ObjectboxSaleRepository()
      : _box = ObjectboxDatabase.box<SaleEntity>(),
        _itemsBox = ObjectboxDatabase.box<SaleItemEntity>();

  final Box<SaleEntity> _box;
  final Box<SaleItemEntity> _itemsBox;

  @override
  Stream<List<Sale>> watchAll() {
    return _box
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toDomain).toList());
  }

  @override
  Future<List<Sale>> getAll() async {
    return _box.getAll().map(_toDomain).toList();
  }

  @override
  Future<Sale?> getById(int id) async {
    final entity = _box.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<List<Sale>> getByDateRange(DateTime start, DateTime end) async {
    return _box
        .query(SaleEntity_.createdAt.betweenDate(start, end))
        .build()
        .find()
        .map(_toDomain)
        .toList();
  }

  @override
  Future<int> save(Sale sale) async {
    final entity = _toEntity(sale);
    final id = _box.put(entity);

    _itemsBox.query(SaleItemEntity_.saleId.equals(id)).build().remove();
    for (final item in sale.items) {
      _itemsBox.put(_toItemEntity(item, id));
    }
    return id;
  }

  @override
  Future<void> delete(int id) async {
    _itemsBox.query(SaleItemEntity_.saleId.equals(id)).build().remove();
    _box.remove(id);
  }

  @override
  Future<int> getNextSaleNumber() async {
    return _box.count() + 1;
  }

  Sale _toDomain(SaleEntity e) {
    final items = _itemsBox
        .query(SaleItemEntity_.saleId.equals(e.id))
        .build()
        .find()
        .map(_toSaleItem)
        .toList();
    return Sale(
      id: e.id,
      saleNumber: e.saleNumber,
      customerId: e.customerId == 0 ? null : e.customerId,
      cashierId: e.cashierId == 0 ? null : e.cashierId,
      items: items,
      paymentMethod: _enumAt(PaymentMethod.values, e.paymentMethod, PaymentMethod.cash),
      status: _enumAt(SaleStatus.values, e.status, SaleStatus.completed),
      discountTotal: e.discountTotal,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  SaleEntity _toEntity(Sale s) {
    return SaleEntity()
      ..id = s.id
      ..saleNumber = s.saleNumber
      ..customerId = s.customerId ?? 0
      ..cashierId = s.cashierId ?? 0
      ..paymentMethod = s.paymentMethod.index
      ..status = s.status.index
      ..discountTotal = s.discountTotal
      ..createdAt = s.createdAt ?? DateTime.now()
      ..updatedAt = s.updatedAt ?? DateTime.now()
      ..syncStatus = s.syncStatus.index;
  }

  SaleItem _toSaleItem(SaleItemEntity e) {
    return SaleItem(
      productId: e.productId,
      productName: e.productName,
      sku: e.sku,
      unitPrice: e.unitPrice,
      costPrice: e.costPrice,
      taxRate: e.taxRate,
      quantity: e.quantity,
      discount: e.discount,
    );
  }

  SaleItemEntity _toItemEntity(SaleItem item, int saleId) {
    return SaleItemEntity()
      ..saleId = saleId
      ..productId = item.productId
      ..productName = item.productName
      ..sku = item.sku
      ..unitPrice = item.unitPrice
      ..costPrice = item.costPrice
      ..taxRate = item.taxRate
      ..quantity = item.quantity
      ..discount = item.discount;
  }
}

T _enumAt<T>(List<T> values, int index, T fallback) {
  if (index < 0 || index >= values.length) return fallback;
  return values[index];
}

SyncStatus _toSyncStatus(int index) {
  if (index < 0 || index >= SyncStatus.values.length) {
    return SyncStatus.synced;
  }
  return SyncStatus.values[index];
}
