import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pos_domain/pos_domain.dart';

class ReturnController extends ChangeNotifier {
  ReturnController({
    required this.returnUseCases,
    required this.saleUseCases,
    required this.customerUseCases,
  }) {
    init();
  }

  final ReturnUseCases returnUseCases;
  final SaleUseCases saleUseCases;
  final CustomerUseCases customerUseCases;

  List<ReturnRecord> _returns = [];
  List<Sale> _sales = [];
  List<Customer> _customers = [];
  StreamSubscription<List<ReturnRecord>>? _returnSubscription;
  StreamSubscription<List<Sale>>? _saleSubscription;
  StreamSubscription<List<Customer>>? _customerSubscription;
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  List<ReturnRecord> get returns => _returns;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<Sale> get returnableSales => _sales
      .where((s) => s.status == SaleStatus.completed)
      .toList()
    ..sort(
      (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
        a.createdAt ?? DateTime(0),
      ),
    );

  void init() {
    _returnSubscription = returnUseCases.watchReturns().listen((returns) {
      _returns = returns;
      _isLoading = false;
      notifyListeners();
    });
    _saleSubscription = saleUseCases.watchSales().listen((sales) {
      _sales = sales;
      notifyListeners();
    });
    _customerSubscription = customerUseCases.watchCustomers().listen((
      customers,
    ) {
      _customers = customers;
      notifyListeners();
    });
  }

  void clearFeedback() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  bool isReturned(int saleId) => _returns.any((r) => r.saleId == saleId);

  String? customerName(int? id) {
    if (id == null) return null;
    return _customers.where((c) => c.id == id).map((c) => c.name).firstOrNull;
  }

  Future<Result<List<ReturnItem>>> returnableItemsFor(int saleId) {
    return returnUseCases.returnableItemsFor(saleId);
  }

  Future<bool> createReturn({
    required int saleId,
    required List<ReturnItem> items,
    String? reason,
  }) async {
    final result = await returnUseCases.createReturn(
      saleId: saleId,
      items: items,
      reason: reason,
    );
    return _handleResult(result, 'Retour enregistré, stock restauré');
  }

  Future<bool> deleteReturn(int id) async {
    final result = await returnUseCases.deleteReturn(id);
    return _handleResult(result, 'Retour supprimé');
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
    _returnSubscription?.cancel();
    _saleSubscription?.cancel();
    _customerSubscription?.cancel();
    super.dispose();
  }
}