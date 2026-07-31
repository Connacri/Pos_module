import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:pos_domain/pos_domain.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  @override
  Stream<User?> watchUser() {
    return _client.auth.onAuthStateChange.map((state) {
      final supaUser = state.session?.user;
      if (supaUser == null) return null;
      return _mapUser(supaUser);
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final supaUser = _client.auth.currentUser;
    return supaUser == null ? null : _mapUser(supaUser);
  }

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final supaUser = response.user;
      if (supaUser == null) {
        throw const AuthFailure('Utilisateur introuvable');
      }
      return _mapUser(supaUser);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
  }

  User _mapUser(sb.User supaUser) {
    final meta = supaUser.userMetadata;
    final role = meta?['role'] as String?;
    return User(
      id: 0,
      email: supaUser.email ?? '',
      name: meta?['name'] as String? ?? supaUser.email?.split('@').first,
      role: UserRole.fromCode(role ?? UserRole.cashier.code),
    );
  }
}
