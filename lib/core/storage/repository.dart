/// Shared types for the Repository pattern.
///
/// Every domain (auth, profiles, mantras, programs, sessions, rewards…)
/// will declare an abstract repository in its `domain/` folder and provide
/// at least one implementation (local) now and a remote one later. UI must
/// only depend on the abstract repository — never on Hive, Drift, or HTTP
/// directly.
library;

/// Result wrapper that makes failures explicit at call sites.
sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
  T? get valueOrNull => switch (this) { Ok<T>(:final value) => value, Err<T>() => null };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Lightweight failure type. Specific repositories can extend this.
class Failure implements Exception {
  const Failure(this.message, {this.code, this.cause});
  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'Failure($code): $message';
}
