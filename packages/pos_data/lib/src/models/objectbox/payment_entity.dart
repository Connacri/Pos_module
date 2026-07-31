import 'package:objectbox/objectbox.dart';

@Entity()
class PaymentEntity {
  @Id(assignable: true)
  int id = 0;

  double amount = 0;

  int method = 0;

  int saleId = 0;

  int invoiceId = 0;

  String? reference;

  DateTime paidAt = DateTime.now();

  int syncStatus = 0;
}
