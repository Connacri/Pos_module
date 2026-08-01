import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import 'package:pos_domain/pos_domain.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required this.saleUseCases,
    required this.productUseCases,
    required this.categoryUseCases,
    required this.customerUseCases,
    required this.invoiceUseCases,
  }) {
    init();
  }

  final SaleUseCases saleUseCases;
  final ProductUseCases productUseCases;
  final CategoryUseCases categoryUseCases;
  final CustomerUseCases customerUseCases;
  final InvoiceUseCases invoiceUseCases;

  List<Sale> _sales = [];
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Customer> _customers = [];
  List<Invoice> _invoices = [];
  final List<StreamSubscription> _subscriptions = [];
  bool _isLoading = true;

  List<Sale> get sales => _sales;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Customer> get customers => _customers;
  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  List<Sale> get completedSales => _sales
      .where(
        (s) =>
            s.status != SaleStatus.cancelled && s.status != SaleStatus.returned,
      )
      .toList();

  int get salesCount => completedSales.length;

  double get totalRevenue => completedSales.fold(0, (sum, s) => sum + s.total);

  double get averageBasket => salesCount == 0 ? 0 : totalRevenue / salesCount;

  double get revenueToday => completedSales
      .where((s) => _isToday(s.createdAt))
      .fold(0, (sum, s) => sum + s.total);

  int get salesTodayCount =>
      completedSales.where((s) => _isToday(s.createdAt)).length;

  int get totalProducts => _products.length;

  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  int get lowStockCount =>
      _products.where((p) => p.isLowStock && !p.isOutOfStock).length;

  double get stockValue => _products.fold(
    0,
    (sum, p) => sum + p.stock * (p.costPrice > 0 ? p.costPrice : p.price),
  );

  int get customerCount => _customers.length;

  double get outstandingAmount => _invoices
      .where(
        (i) =>
            i.status == InvoiceStatus.issued ||
            i.status == InvoiceStatus.overdue,
      )
      .fold(0, (sum, i) => sum + i.total);

  List<(DateTime, double)> get revenueByDay {
    final today = _startOfDay(DateTime.now());
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final amounts = List<double>.filled(7, 0);
    for (final sale in completedSales) {
      final createdAt = sale.createdAt;
      if (createdAt == null) continue;
      final idx = days.indexWhere((d) => d == _startOfDay(createdAt));
      if (idx >= 0) amounts[idx] += sale.total;
    }
    return [for (var i = 0; i < 7; i++) (days[i], amounts[i])];
  }

  List<(String, double)> get revenueByCategory {
    final map = <String, double>{};
    final productById = {for (final p in _products) p.id: p};
    final categoryById = {for (final c in _categories) c.id: c.name};
    for (final sale in completedSales) {
      for (final item in sale.items) {
        final categoryId = productById[item.productId]?.categoryId;
        final name = categoryId == null
            ? 'Sans catégorie'
            : (categoryById[categoryId] ?? 'Sans catégorie');
        map[name] = (map[name] ?? 0) + item.lineTotal;
      }
    }
    final entries = map.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (entries.length <= 6) return entries;
    final top = entries.take(5).toList();
    final rest = entries.skip(5).fold<double>(0, (sum, e) => sum + e.$2);
    return [...top, ('Autres', rest)];
  }

  List<(String, double)> get topProducts {
    final map = <String, double>{};
    for (final sale in completedSales) {
      for (final item in sale.items) {
        map[item.productName] = (map[item.productName] ?? 0) + item.quantity;
      }
    }
    final list = map.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(5).toList();
  }

  void init() {
    _subscriptions.addAll([
      saleUseCases.watchSales().listen((sales) {
        _sales = sales;
        _isLoading = false;
        notifyListeners();
      }),
      productUseCases.watchProducts().listen((products) {
        _products = products;
        notifyListeners();
      }),
      categoryUseCases.watchCategories().listen((categories) {
        _categories = categories;
        notifyListeners();
      }),
      customerUseCases.watchCustomers().listen((customers) {
        _customers = customers;
        notifyListeners();
      }),
      invoiceUseCases.watchInvoices().listen((invoices) {
        _invoices = invoices;
        notifyListeners();
      }),
    ]);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isToday(DateTime? d) =>
    d != null && _startOfDay(d) == _startOfDay(DateTime.now());
