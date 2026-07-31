import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAll();
  Stream<List<Product>> watchLowStock();
  Future<List<Product>> getAll();
  Future<Product?> getById(int id);
  Future<Product?> getBySku(String sku);
  Future<List<Product>> search(String query);
  Future<int> save(Product product);
  Future<void> saveMany(List<Product> products);
  Future<void> delete(int id);
}
