import '../core/failure.dart';
import '../core/result.dart';
import '../entities/enums.dart';
import '../entities/return_item.dart';
import '../entities/return_record.dart';
import '../repositories/product_repository.dart';
import '../repositories/return_repository.dart';
import '../repositories/sale_repository.dart';

class ReturnUseCases {
  ReturnUseCases(
    this._returnRepository,
    this._saleRepository,
    this._productRepository,
  );

  final ReturnRepository _returnRepository;
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;

  Stream<List<ReturnRecord>> watchReturns() => _returnRepository.watchAll();

  Future<Result<List<ReturnRecord>>> getReturns() => _guard(
    _returnRepository.getAll,
  );

  /// Articles restant à retourner pour une vente (quantité déjà retournée déduite).
  Future<Result<List<ReturnItem>>> returnableItemsFor(int saleId) =>
      _guard(() async {
        final sale = await _saleRepository.getById(saleId);
        if (sale == null) {
          throw const NotFoundFailure('Vente introuvable');
        }
        final returnedByProduct = await _returnedByProduct(saleId);
        final result = <ReturnItem>[];
        for (final saleItem in sale.items) {
          final already = returnedByProduct[saleItem.productId] ?? 0;
          final remaining = saleItem.quantity - already;
          if (remaining <= 0) continue;
          result.add(
            ReturnItem(
              productId: saleItem.productId,
              description: saleItem.productName,
              quantity: remaining,
              unitPrice: saleItem.unitPrice,
              taxRate: saleItem.taxRate,
            ),
          );
        }
        if (result.isEmpty) {
          throw const ValidationFailure(
            'Tous les articles de cette vente ont déjà été retournés',
          );
        }
        return result;
      });

  Future<Result<ReturnRecord>> createReturn({
    required int saleId,
    required List<ReturnItem> items,
    String? reason,
  }) => _guard(() async {
    final sale = await _saleRepository.getById(saleId);
    if (sale == null) {
      throw const NotFoundFailure('Vente introuvable');
    }
    if (items.isEmpty) {
      throw const ValidationFailure('Sélectionnez au moins un article à retourner');
    }

    final returnedByProduct = await _returnedByProduct(saleId);
    final now = DateTime.now();

    for (final item in items) {
      final saleItem = sale.items
          .where((si) => si.productId == item.productId)
          .firstOrNull;
      if (saleItem == null) {
        throw NotFoundFailure('Produit introuvable dans la vente');
      }
      final already = returnedByProduct[item.productId] ?? 0;
      final maxQty = saleItem.quantity - already;
      if (item.quantity <= 0 || item.quantity > maxQty) {
        throw ValidationFailure(
          'Quantité invalide pour ${item.description}',
        );
      }
    }

    // Rembourse le stock retourné.
    for (final item in items) {
      final product = await _productRepository.getById(item.productId);
      if (product == null) {
        throw NotFoundFailure('Produit introuvable : ${item.description}');
      }
      await _productRepository.save(
        product.copyWith(stock: product.stock + item.quantity, updatedAt: now),
      );
    }

    // Répartit la remise globale de la vente proportionnellement aux articles retournés.
    final rawSubtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final recordItems = items
        .map(
          (item) => item.copyWith(
            discount: rawSubtotal > 0
                ? sale.discountTotal * ((item.unitPrice * item.quantity) / rawSubtotal)
                : 0,
          ),
        )
        .toList();

    final record = ReturnRecord(
      id: 0,
      saleId: saleId,
      saleNumber: sale.saleNumber,
      customerId: sale.customerId,
      items: recordItems,
      reason: reason,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    final id = await _returnRepository.save(record);

    // Marque la vente comme retournée si tous les articles sont entièrement retournés.
    final allReturned = sale.items.every((saleItem) {
      final already = returnedByProduct[saleItem.productId] ?? 0;
      final addedBack = items
          .where((i) => i.productId == saleItem.productId)
          .fold<double>(0, (sum, i) => sum + i.quantity);
      return already + addedBack >= saleItem.quantity;
    });
    await _saleRepository.save(
      sale.copyWith(
        status: allReturned ? SaleStatus.returned : SaleStatus.completed,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      ),
    );

    return record.copyWith(id: id);
  });

  Future<Result<void>> deleteReturn(int id) => _guard(() async {
    await _returnRepository.delete(id);
    return;
  });

  Future<Map<int, double>> _returnedByProduct(int saleId) async {
    final existing = await _returnRepository.getBySale(saleId);
    final map = <int, double>{};
    for (final record in existing) {
      for (final item in record.items) {
        map[item.productId] = (map[item.productId] ?? 0) + item.quantity;
      }
    }
    return map;
  }

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