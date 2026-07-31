import 'package:objectbox/objectbox.dart';

@Entity()
class SaleEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  String saleNumber = '';

  int customerId = 0;

  int cashierId = 0;

  int paymentMethod = 0;

  int status = 0;

  double discountTotal = 0;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}
