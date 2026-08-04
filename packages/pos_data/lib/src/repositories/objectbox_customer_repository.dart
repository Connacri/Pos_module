import 'package:objectbox/objectbox.dart';

import 'package:pos_domain/pos_domain.dart';

import '../data_sources/objectbox_database.dart';
import '../models/objectbox/customer_entity.dart';
import '../utils/recent_sort.dart';

class ObjectboxCustomerRepository implements CustomerRepository {
  ObjectboxCustomerRepository()
      : _box = ObjectboxDatabase.box<CustomerEntity>();

  final Box<CustomerEntity> _box;

  @override
  Stream<List<Customer>> watchAll() {
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
  Future<List<Customer>> getAll() async {
    return _box.getAll().map(_toDomain).sortedByRecent(
          id: (e) => e.id,
          createdAt: (e) => e.createdAt,
          updatedAt: (e) => e.updatedAt,
        ).toList();
  }

  @override
  Future<Customer?> getById(int id) async {
    final entity = _box.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<List<Customer>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _box
        .getAll()
        .map(_toDomain)
        .where((c) => c.matchesQuery(q))
        .sortedByRecent(
          id: (e) => e.id,
          createdAt: (e) => e.createdAt,
          updatedAt: (e) => e.updatedAt,
        )
        .toList();
  }

  @override
  Future<int> save(Customer customer) async {
    final entity = _toEntity(customer);
    return _box.put(entity);
  }

  @override
  Future<void> delete(int id) async {
    _box.remove(id);
  }

  Customer _toDomain(CustomerEntity e) {
    return Customer(
      id: e.id,
      name: e.name,
      phone: e.phone,
      email: e.email,
      address: e.address,
      company: e.company,
      taxId: e.taxId,
      notes: e.notes,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: _toSyncStatus(e.syncStatus),
    );
  }

  CustomerEntity _toEntity(Customer c) {
    return CustomerEntity()
      ..id = c.id
      ..name = c.name
      ..phone = c.phone
      ..email = c.email
      ..address = c.address
      ..company = c.company
      ..taxId = c.taxId
      ..notes = c.notes
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
