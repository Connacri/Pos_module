import 'package:objectbox/objectbox.dart';

@Entity()
class ReturnItemEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  int returnId = 0;

  int productId = 0;

  String description = '';

  double unitPrice = 0;

  double quantity = 0;

  double taxRate = 0;

  double discount = 0;
}