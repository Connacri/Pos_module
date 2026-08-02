import '../entities/return_record.dart';

abstract class ReturnRepository {
  Stream<List<ReturnRecord>> watchAll();
  Future<List<ReturnRecord>> getAll();
  Future<List<ReturnRecord>> getBySale(int saleId);
  Future<int> save(ReturnRecord record);
  Future<void> delete(int id);
  Future<int> count();
}