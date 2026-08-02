import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pos_domain/pos_domain.dart';

class PosController extends ChangeNotifier {
  PosController({
    required this.productUseCases,
    required this.saleUseCases,
    required this.invoiceUseCases,
  }) {
    init();
  }

  final ProductUseCases productUseCases;
  final SaleUseCases saleUseCases;
  final InvoiceUseCases invoiceUseCases;

  List<Product> _products = [];
  final Map<int, SaleItem> _cart = {};
  String _query = '';
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _discount = 0;
  bool _isCheckingOut = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<List<Product>>? _subscription;

  List<Product> get products => _products;
  List<SaleItem> get cartItems => _cart.values.toList();
  String get query => _query;
  PaymentMethod get paymentMethod => _paymentMethod;
  double get discount => _discount;
  bool get isCheckingOut => _isCheckingOut;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isCartEmpty => _cart.isEmpty;
  bool get isLoading => _subscription == null;

  double get subtotal => cartItems.fold(0, (s, i) => s + i.lineSubtotal);
  double get taxTotal => cartItems.fold(0, (s, i) => s + i.taxAmount);
  double get total => (subtotal + taxTotal) - _discount;
  int get itemCount => cartItems.fold(0, (s, i) => s + i.quantity.round());

  List<Product> get filteredProducts {
    if (_query.trim().isEmpty) return _products;
    return _products.where((p) => p.matchesQuery(_query)).toList();
  }

  void init() {
    _subscription = productUseCases.watchProducts().listen((products) {
      _products = products;
      notifyListeners();
    });
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void clearFeedback() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (product.isOutOfStock) return;
    final existing = _cart[product.id];
    if (existing != null) {
      if (existing.quantity >= product.stock) {
        _error = 'Stock maximum atteint pour ${product.name}';
        notifyListeners();
        return;
      }
      _cart[product.id] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      _cart[product.id] = SaleItem(
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        unitPrice: product.price,
        costPrice: product.costPrice,
        taxRate: product.taxRate,
        quantity: 1,
      );
    }
    _error = null;
    notifyListeners();
  }

  void increment(int productId) {
    final item = _cart[productId];
    if (item == null) return;
    _cart[productId] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  void decrement(int productId) {
    final item = _cart[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _cart.remove(productId);
    } else {
      _cart[productId] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discount = 0;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount.clamp(0, subtotal + taxTotal);
    notifyListeners();
  }

  Future<bool> checkout() async {
    if (isCartEmpty || _isCheckingOut) return false;
    _isCheckingOut = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final sale = Sale(
      id: 0,
      saleNumber: '',
      items: cartItems,
      paymentMethod: _paymentMethod,
      discountTotal: _discount,
    );

    final result = await saleUseCases.createSale(sale);
    _isCheckingOut = false;

    switch (result) {
      case Success<Sale>(:final value):
        final invoiceResult = await invoiceUseCases.createInvoiceFromSale(
          value.id,
        );
        if (invoiceResult is Success) {
          _successMessage =
              'Vente ${value.saleNumber} enregistrée, facture créée';
        } else {
          _error =
              'Vente ${value.saleNumber} enregistrée, mais la facture n\'a pas pu être créée';
        }
        clearCart();
        notifyListeners();
        return true;
      case AppError<Sale>(:final failure):
        _error = failure.message;
        notifyListeners();
        return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
