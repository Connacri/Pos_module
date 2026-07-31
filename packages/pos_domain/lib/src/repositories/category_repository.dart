import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> getAll();
  Future<Category?> getById(int id);
  Future<int> save(Category category);
  Future<void> delete(int id);
}
