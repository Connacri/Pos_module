import 'enums.dart';
import 'return_item.dart';

class ReturnRecord {
  const ReturnRecord({
    required this.id,
    required this.saleId,
    required this.items,
    this.saleNumber,
    this.customerId,
    this.reason,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final int id;
  final int saleId;
  final String? saleNumber;
  final int? customerId;
  final List<ReturnItem> items;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get taxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get refundTotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity.round());

  ReturnRecord copyWith({
    int? id,
    int? saleId,
    List<ReturnItem>? items,
    String? saleNumber,
    int? customerId,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return ReturnRecord(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      items: items ?? this.items,
      saleNumber: saleNumber ?? this.saleNumber,
      customerId: customerId ?? this.customerId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReturnRecord(id: $id, saleId: $saleId)';
}