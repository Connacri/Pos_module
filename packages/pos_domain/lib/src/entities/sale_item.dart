class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.costPrice,
    required this.taxRate,
    required this.quantity,
    this.discount = 0,
  });

  final int productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double costPrice;
  final double taxRate;
  final double quantity;
  final double discount;

  double get lineSubtotal => (unitPrice * quantity) - discount;
  double get taxAmount => lineSubtotal * taxRate;
  double get lineTotal => lineSubtotal + taxAmount;

  SaleItem copyWith({
    int? productId,
    String? productName,
    String? sku,
    double? unitPrice,
    double? costPrice,
    double? taxRate,
    double? quantity,
    double? discount,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      taxRate: taxRate ?? this.taxRate,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() =>
      'SaleItem(productId: $productId, name: $productName, qty: $quantity)';
}
