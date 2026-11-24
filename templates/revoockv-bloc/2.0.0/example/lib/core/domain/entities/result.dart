/// Outcome of an operation that can fail in an expected way: a value of type [T] or a
/// failure of type [F].
///
/// [F] is the failure type of the feature — an `enum` (`NoteFailure.add`) or a sealed
/// class when a failure carries data. It says what went wrong, not how to say it: the
/// presentation layer turns it into text in the user's language.
sealed class Result<T, F> {
  const Result();

  /// Successful outcome carrying [value].
  const factory Result.success(T value) = SuccessResult<T, F>;

  /// Failed outcome with [failure].
  const factory Result.failure(F failure) = FailureResult<T, F>;

  /// The single shared success for commands that return no value.
  ///
  /// `Never` is a subtype of every type, so `Result<void, Never>` is a
  /// `Result<void, NoteFailure>` too.
  static const Result<void, Never> ok = SuccessResult<void, Never>(null);

  /// Whether the operation succeeded.
  bool get isSuccess => this is SuccessResult<T, F>;

  /// Whether the operation failed.
  bool get isFailure => this is FailureResult<T, F>;

  /// Calls [success] with the value or [failure] with the failure.
  R when<R>({required R Function(T value) success, required R Function(F failure) failure}) => switch (this) {
    SuccessResult<T, F>(:final T value) => success(value),
    FailureResult<T, F>(failure: final F reason) => failure(reason),
  };

  /// The same result with the failure turned into [G] by [map] — for a use case that
  /// passes on a failure of another feature as its own.
  Result<T, G> mapFailure<G>(G Function(F failure) map) => switch (this) {
    SuccessResult<T, F>(:final T value) => SuccessResult<T, G>(value),
    FailureResult<T, F>(:final F failure) => FailureResult<T, G>(map(failure)),
  };
}

/// Successful [Result].
final class SuccessResult<T, F> extends Result<T, F> {
  /// The produced value.
  final T value;

  /// Creates a successful result with [value].
  const SuccessResult(this.value);
}

/// Failed [Result].
final class FailureResult<T, F> extends Result<T, F> {
  /// What went wrong.
  final F failure;

  /// Creates a failed result with [failure].
  const FailureResult(this.failure);
}
