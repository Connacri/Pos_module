import 'package:objectbox/objectbox.dart';

@Entity()
class ReturnRecordEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  int saleId = 0;

  String saleNumber = '';

  int customerId = 0;

  String? reason;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}