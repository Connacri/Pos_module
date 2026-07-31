import 'enums.dart';

class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.method,
    this.saleId,
    this.invoiceId,
    this.reference,
    this.paidAt,
    this.syncStatus = SyncStatus.synced,
  });

  final int id;
  final double amount;
  final PaymentMethod method;
  final int? saleId;
  final int? invoiceId;
  final String? reference;
  final DateTime? paidAt;
  final SyncStatus syncStatus;

  Payment copyWith({
    int? id,
    double? amount,
    PaymentMethod? method,
    int? saleId,
    int? invoiceId,
    String? reference,
    DateTime? paidAt,
    SyncStatus? syncStatus,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      saleId: saleId ?? this.saleId,
      invoiceId: invoiceId ?? this.invoiceId,
      reference: reference ?? this.reference,
      paidAt: paidAt ?? this.paidAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, amount: $amount, method: ${method.code})';
}
