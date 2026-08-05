class ReturnItem {
  const ReturnItem({
    required this.productId,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.purchasedQuantity,
    this.taxRate = 0,
    this.discount = 0,
  });

  final int productId;
  final String description;
  final double unitPrice;

  /// Quantité restant à retourner (achetée - déjà retournée).
  final double quantity;

  /// Quantité achetée initialement sur la vente (null si inconnue).
  final double? purchasedQuantity;

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
    double? purchasedQuantity,
    double? taxRate,
    double? discount,
  }) {
    return ReturnItem(
      productId: productId ?? this.productId,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      purchasedQuantity: purchasedQuantity ?? this.purchasedQuantity,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() => 'ReturnItem(productId: $productId, qty: $quantity)';
}