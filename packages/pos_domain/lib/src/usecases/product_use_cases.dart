import '../core/failure.dart';
import '../core/result.dart';
import '../entities/enums.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ProductUseCases {
  ProductUseCases(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> watchProducts() => _repository.watchAll();

  Stream<List<Product>> watchLowStockProducts() => _repository.watchLowStock();

  Future<Result<List<Product>>> getAllProducts() => _guard(_repository.getAll);

  Future<Result<List<Product>>> searchProducts(String query) =>
      _guard(() => _repository.search(query));

  Future<Result<Product>> createProduct(Product product) async {
    if (product.sku.trim().isEmpty) {
      return const AppError(ValidationFailure('Le SKU est requis'));
    }
    if (product.name.trim().isEmpty) {
      return const AppError(ValidationFailure('Le nom est requis'));
    }
    if (product.price < 0) {
      return const AppError(ValidationFailure('Le prix ne peut pas être négatif'));
    }
    return _guard(() async {
      final now = DateTime.now();
      final draft = product.copyWith(
        id: 0,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );
      final id = await _repository.save(draft);
      return draft.copyWith(id: id);
    });
  }

  Future<Result<Product>> updateProduct(Product product) => _guard(() async {
        final updated = product.copyWith(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await _repository.save(updated);
        return updated;
      });

  Future<Result<void>> deleteProduct(int id) => _guard(() async {
        await _repository.delete(id);
        return;
      });

  Future<Result<void>> adjustStock(int id, double delta) => _guard(() async {
        final existing = await _repository.getById(id);
        if (existing == null) {
          throw const NotFoundFailure('Produit introuvable');
        }
        final newStock = existing.stock + delta;
        if (newStock < 0) {
          throw StockFailure('Stock insuffisant pour ${existing.name}');
        }
        await _repository.save(
          existing.copyWith(
            stock: newStock,
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
        );
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
