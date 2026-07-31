import 'enums.dart';
import 'invoice_item.dart';

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.saleId,
    this.customerId,
    required this.items,
    this.status = InvoiceStatus.draft,
    this.discountTotal = 0,
    this.companyName,
    this.companyAddress,
    this.companyTaxId,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final int id;
  final String invoiceNumber;
  final int? saleId;
  final int? customerId;
  final List<InvoiceItem> items;
  final InvoiceStatus status;
  final double discountTotal;
  final String? companyName;
  final String? companyAddress;
  final String? companyTaxId;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get taxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => (subtotal + taxTotal) - discountTotal;
  bool get isOverdue => status == InvoiceStatus.issued && dueDate != null && dueDate!.isBefore(DateTime.now());

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? saleId,
    int? customerId,
    List<InvoiceItem>? items,
    InvoiceStatus? status,
    double? discountTotal,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      status: status ?? this.status,
      discountTotal: discountTotal ?? this.discountTotal,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyTaxId: companyTaxId ?? this.companyTaxId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Invoice(id: $id, number: $invoiceNumber, total: $total)';
}
