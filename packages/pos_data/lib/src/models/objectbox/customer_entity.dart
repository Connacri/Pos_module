import 'package:objectbox/objectbox.dart';

@Entity()
class CustomerEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  String name = '';

  String? phone;

  String? email;

  String? address;

  String? company;

  String? taxId;

  String? notes;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}
