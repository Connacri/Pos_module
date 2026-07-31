import 'failure.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class AppError<T> extends Result<T> {
  const AppError(this.failure);

  final Failure failure;
}

extension ResultX<T> on Result<T> {
  T get valueOrThrow {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => value,
      AppError<T>(:final failure) => throw failure,
    };
  }

  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onError) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => onSuccess(value),
      AppError<T>(:final failure) => onError(failure),
    };
  }
}
