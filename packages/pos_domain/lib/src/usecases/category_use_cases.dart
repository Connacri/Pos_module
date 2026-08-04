import '../core/failure.dart';
import '../core/result.dart';
import '../entities/category.dart';
import '../entities/enums.dart';
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
      final now = DateTime.now();
      final draft = category.copyWith(
        id: 0,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );
      final id = await _repository.save(draft);
      return draft.copyWith(id: id);
    });
  }

  Future<Result<Category>> updateCategory(Category category) => _guard(() async {
        final updated = category.copyWith(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await _repository.save(updated);
        return updated;
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
