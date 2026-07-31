import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> watchUser();
  Future<User?> getCurrentUser();
  Future<User> signIn(String email, String password);
  Future<void> signOut();
}
