import '../core/failure.dart';
import '../core/result.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerUseCases {
  CustomerUseCases(this._repository);

  final CustomerRepository _repository;

  Stream<List<Customer>> watchCustomers() => _repository.watchAll();

  Future<Result<List<Customer>>> getAllCustomers() => _guard(_repository.getAll);

  Future<Result<List<Customer>>> searchCustomers(String query) =>
      _guard(() => _repository.search(query));

  Future<Result<Customer>> createCustomer(Customer customer) async {
    if (customer.name.trim().isEmpty) {
      return const AppError(ValidationFailure('Le nom du client est requis'));
    }
    return _guard(() async {
      final id = await _repository.save(customer);
      return customer.copyWith(id: id);
    });
  }

  Future<Result<Customer>> updateCustomer(Customer customer) => _guard(() async {
        await _repository.save(customer);
        return customer;
      });

  Future<Result<void>> deleteCustomer(int id) => _guard(() async {
        await _repository.delete(id);
        return;
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Failure catch (f) {
      return AppError(f);
    } catch (e) {
      return AppError(DatabaseFailure(e.toString()));
    }
  }
}
