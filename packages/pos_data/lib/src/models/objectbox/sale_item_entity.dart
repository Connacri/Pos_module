import 'package:objectbox/objectbox.dart';

@Entity()
class SaleItemEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  int saleId = 0;

  int productId = 0;

  String productName = '';

  String sku = '';

  double unitPrice = 0;

  double costPrice = 0;

  double taxRate = 0;

  double quantity = 0;

  double discount = 0;
}
