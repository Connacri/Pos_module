import 'package:test/test.dart';

import 'package:pos_domain/pos_domain.dart';

void main() {
  group('Result', () {
    test('Success fournit la valeur via fold', () {
      const result = Success<int>(42);
      expect(
        result.fold((v) => v, (f) => f.message),
        42,
      );
    });

    test('AppError expose la Failure via fold', () {
      final result = AppError<int>(const ValidationFailure('invalide'));
      expect(
        result.fold((v) => '$v', (f) => f.message),
        'invalide',
      );
    });

    test('valueOrThrow lance la failure pour AppError', () {
      final result = AppError<int>(const NotFoundFailure('absent'));
      expect(() => result.valueOrThrow, throwsA(isA<NotFoundFailure>()));
    });
  });

  group('Failure', () {
    test('messages par défaut', () {
      expect(const NotFoundFailure().message, 'Ressource introuvable');
      expect(const DatabaseFailure().message, 'Erreur de base de données');
      expect(const NetworkFailure().message, 'Erreur réseau');
    });

    test('toString contient le type et le message', () {
      expect(
        const AuthFailure('refusé').toString(),
        'AuthFailure: refusé',
      );
    });
  });
}
