import 'enums.dart';

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.categoryId,
    required this.price,
    required this.costPrice,
    required this.taxRate,
    required this.stock,
    this.lowStockThreshold = 5,
    this.barcode,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final int id;
  final String sku;
  final String name;
  final String? description;
  final int? categoryId;
  final double price;
  final double costPrice;
  final double taxRate;
  final double stock;
  final double lowStockThreshold;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  static const _imageSeparator = '\n';

  bool get isLowStock => stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;
  double get margin => price - costPrice;

  /// All stored photo URLs. [imageUrl] may hold several URLs joined by a
  /// newline; this exposes them as a clean list.
  List<String> get imageUrls => (imageUrl ?? '')
      .split(_imageSeparator)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  /// First photos, to render a thumbnail or a cover in a carousel.
  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;
  String get fallbackImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  static String joinImages(List<String> urls) => urls.join(_imageSeparator);

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        sku.toLowerCase().contains(q) ||
        (barcode?.toLowerCase().contains(q) ?? false);
  }

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    String? description,
    int? categoryId,
    double? price,
    double? costPrice,
    double? taxRate,
    double? stock,
    double? lowStockThreshold,
    String? barcode,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      taxRate: taxRate ?? this.taxRate,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product(id: $id, sku: $sku, name: $name)';
}
