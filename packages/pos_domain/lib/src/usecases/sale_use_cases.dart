import '../core/failure.dart';
import '../core/result.dart';
import '../entities/enums.dart';
import '../entities/sale.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

class SaleUseCases {
  SaleUseCases(this._saleRepository, this._productRepository);

  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;

  Stream<List<Sale>> watchSales() => _saleRepository.watchAll();

  Future<Result<List<Sale>>> getSales() => _guard(_saleRepository.getAll);

  Future<Result<Sale>> getSaleById(int id) => _guard(() async {
        final sale = await _saleRepository.getById(id);
        if (sale == null) {
          throw const NotFoundFailure('Vente introuvable');
        }
        return sale;
      });

  Future<Result<List<Sale>>> getSalesByRange(DateTime start, DateTime end) =>
      _guard(() => _saleRepository.getByDateRange(start, end));

  Future<Result<Sale>> createSale(Sale draft) async {
    if (draft.isEmpty) {
      return const AppError(ValidationFailure('Le panier est vide'));
    }
    try {
      for (final item in draft.items) {
        final product = await _productRepository.getById(item.productId);
        if (product == null) {
          throw NotFoundFailure('Produit introuvable : ${item.productName}');
        }
        if (item.quantity > product.stock) {
          throw StockFailure(
            'Stock insuffisant pour ${product.name} (disponible : ${product.stock})',
          );
        }
      }

      final number = await _saleRepository.getNextSaleNumber();
      final now = DateTime.now();
      final sale = draft.copyWith(
        id: 0,
        saleNumber: number.toString().padLeft(6, '0'),
        status: SaleStatus.completed,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );

      final saleId = await _saleRepository.save(sale);

      for (final item in draft.items) {
        final product = await _productRepository.getById(item.productId);
        if (product != null) {
          await _productRepository.save(
            product.copyWith(stock: product.stock - item.quantity),
          );
        }
      }

      return Success(sale.copyWith(id: saleId));
    } on Failure catch (f) {
      return AppError(f);
    } catch (e) {
      return AppError(DatabaseFailure(e.toString()));
    }
  }

  Future<Result<void>> cancelSale(int id) => _guard(() async {
        final sale = await _saleRepository.getById(id);
        if (sale == null) {
          throw const NotFoundFailure('Vente introuvable');
        }
        await _saleRepository.save(sale.copyWith(status: SaleStatus.cancelled));

        for (final item in sale.items) {
          final product = await _productRepository.getById(item.productId);
          if (product != null) {
            await _productRepository.save(
              product.copyWith(stock: product.stock + item.quantity),
            );
          }
        }
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
