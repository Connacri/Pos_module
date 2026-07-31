enum UserRole {
  admin('admin'),
  cashier('cashier'),
  manager('manager');

  const UserRole(this.code);

  final String code;

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (r) => r.code == code,
      orElse: () => UserRole.cashier,
    );
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.role = UserRole.cashier,
    this.isActive = true,
  });

  final int id;
  final String email;
  final String? name;
  final UserRole role;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, role: ${role.code})';
}
