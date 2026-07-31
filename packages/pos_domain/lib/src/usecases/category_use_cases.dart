import '../core/failure.dart';
import '../core/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class CategoryUseCases {
  CategoryUseCases(this._repository);

  final CategoryRepository _repository;

  Stream<List<Category>> watchCategories() => _repository.watchAll();

  Future<Result<List<Category>>> getAllCategories() => _guard(_repository.getAll);

  Future<Result<Category>> createCategory(Category category) async {
    if (category.name.trim().isEmpty) {
      return const AppError(ValidationFailure('Le nom de la catégorie est requis'));
    }
    return _guard(() async {
      final id = await _repository.save(category);
      return category.copyWith(id: id);
    });
  }

  Future<Result<Category>> updateCategory(Category category) => _guard(() async {
        await _repository.save(category);
        return category;
      });

  Future<Result<void>> deleteCategory(int id) => _guard(() async {
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
