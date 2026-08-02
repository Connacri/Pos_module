import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import 'package:pos_domain/pos_domain.dart';

/// Uploads a product photo, returning a public URL (or null on failure).
/// Injected from the app host so the inventory package stays decoupled from
/// the data/storage layer.
typedef ProductImageUploader = Future<String?> Function(
  Uint8List bytes,
  String fileName,
);

class InventoryController extends ChangeNotifier {
  InventoryController({
    required this.productUseCases,
    required this.categoryUseCases,
    this.uploader,
  }) {
    init();
  }

  final ProductUseCases productUseCases;
  final CategoryUseCases categoryUseCases;
  final ProductImageUploader? uploader;

  List<Product> _products = [];
  List<Category> _categories = [];
  StreamSubscription<List<Product>>? _subscription;
  StreamSubscription<List<Category>>? _categorySubscription;
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void init() {
    _subscription = productUseCases.watchProducts().listen((products) {
      _products = products;
      _isLoading = false;
      notifyListeners();
    });
    _categorySubscription =
        categoryUseCases.watchCategories().listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

  void clearFeedback() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void showError(String message) {
    _error = message;
    notifyListeners();
  }

  void showSuccess(String message) {
    _successMessage = message;
    notifyListeners();
  }

  Future<bool> saveProduct(Product product, {bool isNew = false}) async {
    final result = isNew
        ? await productUseCases.createProduct(product)
        : await productUseCases.updateProduct(product);
    return result.fold(
      (_) {
        _successMessage = isNew ? 'Produit ajouté' : 'Produit modifié';
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

  Future<bool> deleteProduct(int id) async {
    final result = await productUseCases.deleteProduct(id);
    return result.fold(
      (_) {
        _successMessage = 'Produit supprimé';
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

  Future<bool> adjustStock(int id, double delta) async {
    final result = await productUseCases.adjustStock(id, delta);
    return result.fold(
      (_) {
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
    _subscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }
}
