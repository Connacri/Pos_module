import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/invoice_entity.dart';
import '../models/objectbox/invoice_item_entity.dart';
import '../../objectbox.g.dart';

class ObjectboxInvoiceRepository implements InvoiceRepository {
  ObjectboxInvoiceRepository()
      : _box = ObjectboxDatabase.box<InvoiceEntity>(),
        _itemsBox = ObjectboxDatabase.box<InvoiceItemEntity>();

  final Box<InvoiceEntity> _box;
  final Box<InvoiceItemEntity> _itemsBox;

  @override
  Stream<List<Invoice>> watchAll() {
    return _box
        .query()
        .order(InvoiceEntity_.id, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toDomain).toList());
  }

  @override
  Future<List<Invoice>> getAll() async {
    return _box
        .query()
        .order(InvoiceEntity_.id, flags: Order.descending)
        .build()
        .find()
        .map(_toDomain)
        .toList();
  }

  @override
  Future<Invoice?> getById(int id) async {
    final entity = _box.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<int> save(Invoice invoice) async {
    final entity = _toEntity(invoice);
    final id = _box.put(entity);

    _itemsBox.query(InvoiceItemEntity_.invoiceId.equals(id)).build().remove();
    for (final item in invoice.items) {
      _itemsBox.put(_toItemEntity(item, id));
    }
    return id;
  }

  @override
  Future<void> delete(int id) async {
    _itemsBox.query(InvoiceItemEntity_.invoiceId.equals(id)).build().remove();
    _box.remove(id);
  }

  @override
  Future<int> getNextInvoiceNumber() async {
    var maxNumber = 0;
    for (final invoice in _box.getAll()) {
      final value = int.tryParse(invoice.invoiceNumber);
      if (value != null && value > maxNumber) maxNumber = value;
    }
    return maxNumber + 1;
  }

  Invoice _toDomain(InvoiceEntity e) {
    final items = _itemsBox
        .query(InvoiceItemEntity_.invoiceId.equals(e.id))
        .build()
        .find()
        .map(_toInvoiceItem)
        .toList();
    return Invoice(
      id: e.id,
      invoiceNumber: e.invoiceNumber,
      saleId: e.saleId == 0 ? null : e.saleId,
      customerId: e.customerId == 0 ? null : e.customerId,
      items: items,
      status: _enumAt(InvoiceStatus.values, e.status, InvoiceStatus.draft),
      discountTotal: e.discountTotal,
      companyName: e.companyName,
      companyAddress: e.companyAddress,
      companyTaxId: e.companyTaxId,
      dueDate: e.dueDate,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  InvoiceEntity _toEntity(Invoice i) {
    return InvoiceEntity()
      ..id = i.id
      ..invoiceNumber = i.invoiceNumber
      ..saleId = i.saleId ?? 0
      ..customerId = i.customerId ?? 0
      ..status = i.status.index
      ..discountTotal = i.discountTotal
      ..companyName = i.companyName
      ..companyAddress = i.companyAddress
      ..companyTaxId = i.companyTaxId
      ..dueDate = i.dueDate
      ..createdAt = i.createdAt ?? DateTime.now()
      ..updatedAt = i.updatedAt ?? DateTime.now()
      ..syncStatus = i.syncStatus.index;
  }

  InvoiceItem _toInvoiceItem(InvoiceItemEntity e) {
    return InvoiceItem(
      productId: e.productId,
      description: e.description,
      unitPrice: e.unitPrice,
      quantity: e.quantity,
      taxRate: e.taxRate,
      discount: e.discount,
    );
  }

  InvoiceItemEntity _toItemEntity(InvoiceItem item, int invoiceId) {
    return InvoiceItemEntity()
      ..invoiceId = invoiceId
      ..productId = item.productId
      ..description = item.description
      ..unitPrice = item.unitPrice
      ..quantity = item.quantity
      ..taxRate = item.taxRate
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
