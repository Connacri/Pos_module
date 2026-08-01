import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pos_domain/pos_domain.dart';

class BillingController extends ChangeNotifier {
  BillingController({
    required this.invoiceUseCases,
    required this.customerUseCases,
    required this.saleUseCases,
  }) {
    init();
  }

  final InvoiceUseCases invoiceUseCases;
  final CustomerUseCases customerUseCases;
  final SaleUseCases saleUseCases;

  List<Invoice> _invoices = [];
  List<Customer> _customers = [];
  List<Sale> _sales = [];
  StreamSubscription<List<Invoice>>? _invoiceSubscription;
  StreamSubscription<List<Customer>>? _customerSubscription;
  StreamSubscription<List<Sale>>? _saleSubscription;
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  List<Invoice> get invoices => _invoices;
  List<Customer> get customers => _customers;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  double get totalOutstanding => _invoices
      .where(
        (i) =>
            i.status == InvoiceStatus.issued ||
            i.status == InvoiceStatus.overdue,
      )
      .fold(0, (sum, i) => sum + i.total);

  int get overdueCount => _invoices.where((i) => i.isOverdue).length;

  void init() {
    _invoiceSubscription = invoiceUseCases.watchInvoices().listen((invoices) {
      _invoices = invoices;
      _isLoading = false;
      notifyListeners();
    });
    _customerSubscription = customerUseCases.watchCustomers().listen((
      customers,
    ) {
      _customers = customers;
      notifyListeners();
    });
    _saleSubscription = saleUseCases.watchSales().listen((sales) {
      _sales = sales;
      notifyListeners();
    });
  }

  void clearFeedback() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  String? customerName(int? id) {
    if (id == null) return null;
    return _customers.where((c) => c.id == id).map((c) => c.name).firstOrNull;
  }

  Future<bool> markAsPaid(int id) async {
    final result = await invoiceUseCases.markAsPaid(id);
    return _handleResult(result, 'Facture marquée comme payée');
  }

  Future<bool> updateStatus(int id, InvoiceStatus status) async {
    final result = await invoiceUseCases.updateInvoiceStatus(id, status);
    return _handleResult(result, 'Statut mis à jour');
  }

  Future<bool> createFromSale(int saleId) async {
    final result = await invoiceUseCases.createInvoiceFromSale(saleId);
    return _handleResult(result, 'Facture créée');
  }

  Future<bool> deleteInvoice(int id) async {
    final result = await invoiceUseCases.deleteInvoice(id);
    return _handleResult(result, 'Facture supprimée');
  }

  bool _handleResult<T>(Result<T> result, String success) {
    return result.fold(
      (_) {
        _successMessage = success;
        notifyListeners();
        return true;
      },
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  @override
  void dispose() {
    _invoiceSubscription?.cancel();
    _customerSubscription?.cancel();
    _saleSubscription?.cancel();
    super.dispose();
  }
}
