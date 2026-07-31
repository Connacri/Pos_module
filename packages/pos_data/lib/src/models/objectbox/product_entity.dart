import 'package:objectbox/objectbox.dart';

@Entity()
class ProductEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  String sku = '';

  String name = '';

  String? description;

  int categoryId = 0;

  double price = 0;

  double costPrice = 0;

  double taxRate = 0;

  double stock = 0;

  double lowStockThreshold = 5;

  String? barcode;

  String? imageUrl;

  bool isActive = true;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}
