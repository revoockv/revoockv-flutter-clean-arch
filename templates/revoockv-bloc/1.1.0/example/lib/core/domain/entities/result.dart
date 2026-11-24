/// Outcome of an operation that can fail in an expected way.
sealed class Result<T> {
  const Result();

  /// Successful outcome carrying [value].
  const factory Result.success(T value) = SuccessResult<T>;

  /// Failed outcome with a human-readable [error] for the UI.
  const factory Result.failure(String error) = FailureResult<T>;

  /// The single shared success for commands that return no value.
  static const Result<void> ok = SuccessResult<void>(null);

  /// Whether the operation succeeded.
  bool get isSuccess => this is SuccessResult<T>;

  /// Whether the operation failed.
  bool get isFailure => this is FailureResult<T>;

  /// Calls [success] with the value or [failure] with the error message.
  R when<R>({
    required R Function(T value) success,
    required R Function(String error) failure,
  }) =>
      switch (this) {
        SuccessResult<T>(:final T value) => success(value),
        FailureResult<T>(:final String error) => failure(error),
      };
}

/// Successful [Result].
final class SuccessResult<T> extends Result<T> {
  /// The produced value.
  final T value;

  /// Creates a successful result with [value].
  const SuccessResult(this.value);
}

/// Failed [Result].
final class FailureResult<T> extends Result<T> {
  /// Human-readable error message.
  final String error;

  /// Creates a failed result with [error].
  const FailureResult(this.error);
}
