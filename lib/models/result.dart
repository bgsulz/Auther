/// A Result type for explicit error handling without exceptions.
/// Uses Dart 3 sealed classes for exhaustive pattern matching.
sealed class Result<T> {
  const Result();

  /// Returns true if this is a Success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure
  bool get isFailure => this is Failure<T>;

  /// Returns the value if Success, otherwise returns null
  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Failure() => null,
      };

  /// Returns the value if Success, otherwise returns the provided default
  T valueOr(T defaultValue) => switch (this) {
        Success(value: final v) => v,
        Failure() => defaultValue,
      };

  /// Returns the error message if Failure, otherwise returns null
  String? get errorOrNull => switch (this) {
        Success() => null,
        Failure(message: final m) => m,
      };

  /// Maps the success value to a new type
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(value: final v) => Success(transform(v)),
        Failure(message: final m, error: final e) => Failure(m, e),
      };

  /// Flat maps the success value to a new Result
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success(value: final v) => transform(v),
        Failure(message: final m, error: final e) => Failure(m, e),
      };

  /// Executes callback based on success or failure
  void when({
    required void Function(T value) success,
    required void Function(String message, Object? error) failure,
  }) {
    switch (this) {
      case Success(value: final v):
        success(v);
      case Failure(message: final m, error: final e):
        failure(m, e);
    }
  }
}

/// Represents a successful result with a value
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result with an error message and optional error object
final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;

  const Failure(this.message, [this.error]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          error == other.error;

  @override
  int get hashCode => Object.hash(message, error);

  @override
  String toString() => 'Failure($message${error != null ? ', $error' : ''})';
}
