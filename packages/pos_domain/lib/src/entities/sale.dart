import 'enums.dart';
import 'sale_item.dart';

class Sale {
  const Sale({
    required this.id,
    required this.saleNumber,
    this.customerId,
    this.cashierId,
    required this.items,
    required this.paymentMethod,
    this.status = SaleStatus.completed,
    this.discountTotal = 0,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final int id;
  final String saleNumber;
  final int? customerId;
  final int? cashierId;
  final List<SaleItem> items;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final double discountTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get taxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => (subtotal + taxTotal) - discountTotal;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity.round());
  bool get isEmpty => items.isEmpty;

  Sale copyWith({
    int? id,
    String? saleNumber,
    int? customerId,
    int? cashierId,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
    double? discountTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Sale(
      id: id ?? this.id,
      saleNumber: saleNumber ?? this.saleNumber,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      discountTotal: discountTotal ?? this.discountTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sale && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Sale(id: $id, number: $saleNumber, total: $total)';
}
