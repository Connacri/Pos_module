import '../core/failure.dart';
import '../core/result.dart';
import '../entities/enums.dart';
import '../entities/invoice.dart';
import '../entities/invoice_item.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/sale_repository.dart';

class InvoiceUseCases {
  InvoiceUseCases(this._invoiceRepository, this._saleRepository);

  final InvoiceRepository _invoiceRepository;
  final SaleRepository _saleRepository;

  Stream<List<Invoice>> watchInvoices() => _invoiceRepository.watchAll();

  Future<Result<List<Invoice>>> getInvoices() => _guard(_invoiceRepository.getAll);

  Future<Result<Invoice>> getInvoiceById(int id) => _guard(() async {
        final invoice = await _invoiceRepository.getById(id);
        if (invoice == null) {
          throw const NotFoundFailure('Facture introuvable');
        }
        return invoice;
      });

  Future<Result<Invoice>> createInvoiceFromSale(int saleId) => _guard(() async {
        final sale = await _saleRepository.getById(saleId);
        if (sale == null) {
          throw const NotFoundFailure('Vente introuvable');
        }
        if (sale.isEmpty) {
          throw const ValidationFailure('La vente est vide');
        }

        final number = await _invoiceRepository.getNextInvoiceNumber();
        final now = DateTime.now();
        final invoice = Invoice(
          id: 0,
          invoiceNumber: number.toString().padLeft(6, '0'),
          saleId: sale.id,
          customerId: sale.customerId,
          items: sale.items
              .map(
                (item) => InvoiceItem(
                  productId: item.productId,
                  description: item.productName,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                  taxRate: item.taxRate,
                  discount: item.discount,
                ),
              )
              .toList(),
          status: InvoiceStatus.issued,
          discountTotal: sale.discountTotal,
          dueDate: now.add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
        );

        final id = await _invoiceRepository.save(invoice);
        return invoice.copyWith(id: id);
      });

  Future<Result<Invoice>> updateInvoiceStatus(int id, InvoiceStatus status) =>
      _guard(() async {
        final invoice = await _invoiceRepository.getById(id);
        if (invoice == null) {
          throw const NotFoundFailure('Facture introuvable');
        }
        final updated = invoice.copyWith(status: status, updatedAt: DateTime.now());
        await _invoiceRepository.save(updated);
        return updated;
      });

  Future<Result<Invoice>> markAsPaid(int id) =>
      updateInvoiceStatus(id, InvoiceStatus.paid);

  Future<Result<void>> deleteInvoice(int id) => _guard(() async {
        await _invoiceRepository.delete(id);
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
