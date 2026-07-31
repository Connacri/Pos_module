import '../core/failure.dart';
import '../core/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/sync_repository.dart';

class SyncUseCases {
  SyncUseCases(this._syncRepository, this._authRepository);

  final SyncRepository _syncRepository;
  final AuthRepository _authRepository;

  Stream<bool> watchOnline() => _syncRepository.watchOnline();

  Stream<User?> watchCurrentUser() => _authRepository.watchUser();

  Future<Result<User?>> getCurrentUser() => _guard(_authRepository.getCurrentUser);

  Future<Result<User>> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AppError(ValidationFailure('Email et mot de passe requis'));
    }
    try {
      final user = await _authRepository.signIn(email, password);
      return Success(user);
    } on Failure catch (f) {
      return AppError(f);
    } catch (e) {
      return AppError(AuthFailure(e.toString()));
    }
  }

  Future<Result<void>> signOut() => _guard(_authRepository.signOut);

  Future<Result<DateTime?>> lastSyncAt() => _guard(_syncRepository.lastSyncAt);

  Future<Result<void>> syncAll() => _guard(() async {
        await _syncRepository.syncAll();
        return;
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Failure catch (f) {
      return AppError(f);
    } catch (e) {
      return AppError(SyncFailure(e.toString()));
    }
  }
}
