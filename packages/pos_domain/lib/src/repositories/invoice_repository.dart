import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Stream<List<Invoice>> watchAll();
  Future<List<Invoice>> getAll();
  Future<Invoice?> getById(int id);
  Future<int> save(Invoice invoice);
  Future<void> delete(int id);
  Future<int> getNextInvoiceNumber();
}
