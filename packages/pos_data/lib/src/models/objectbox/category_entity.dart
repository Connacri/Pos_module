import 'package:objectbox/objectbox.dart';

@Entity()
class CategoryEntity {
  @Id(assignable: true)
  int id = 0;

  @Index()
  String name = '';

  int parentId = 0;

  int sortOrder = 0;

  bool isActive = true;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int syncStatus = 0;
}
