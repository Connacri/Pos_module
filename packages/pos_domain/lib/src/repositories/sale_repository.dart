import '../entities/sale.dart';

abstract class SaleRepository {
  Stream<List<Sale>> watchAll();
  Future<List<Sale>> getAll();
  Future<Sale?> getById(int id);
  Future<List<Sale>> getByDateRange(DateTime start, DateTime end);
  Future<int> save(Sale sale);
  Future<void> delete(int id);
  Future<int> getNextSaleNumber();
}
