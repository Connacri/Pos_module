class ReturnItem {
  const ReturnItem({
    required this.productId,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.taxRate = 0,
    this.discount = 0,
  });

  final int productId;
  final String description;
  final double unitPrice;
  final double quantity;
  final double taxRate;
  final double discount;

  double get lineSubtotal => (unitPrice * quantity) - discount;
  double get taxAmount => lineSubtotal * taxRate;
  double get lineTotal => lineSubtotal + taxAmount;

  ReturnItem copyWith({
    int? productId,
    String? description,
    double? unitPrice,
    double? quantity,
    double? taxRate,
    double? discount,
  }) {
    return ReturnItem(
      productId: productId ?? this.productId,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() => 'ReturnItem(productId: $productId, qty: $quantity)';
}