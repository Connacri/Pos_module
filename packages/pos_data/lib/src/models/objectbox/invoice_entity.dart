import 'package:objectbox/objectbox.dart';

@Entity()
class InvoiceEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  String invoiceNumber = '';

  int saleId = 0;

  int customerId = 0;

  int status = 0;

  double discountTotal = 0;

  String? companyName;

  String? companyAddress;

  String? companyTaxId;

  DateTime? dueDate;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}
