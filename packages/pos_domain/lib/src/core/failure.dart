sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Erreur de base de données']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Erreur réseau']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erreur d\'authentification']);
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Erreur de synchronisation']);
}

class StockFailure extends Failure {
  const StockFailure(super.message);
}
