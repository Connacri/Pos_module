import '../entities/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> watchAll();
  Future<List<Customer>> getAll();
  Future<Customer?> getById(int id);
  Future<List<Customer>> search(String query);
  Future<int> save(Customer customer);
  Future<void> delete(int id);
}
