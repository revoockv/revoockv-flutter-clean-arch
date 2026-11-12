import 'result.dart';

/// The current state of a result that changes over time — of a user action or of
/// live data — with your own data of type [T] on success.
///
/// `Future<Result<T>>` is one answer to one call; [ResultState] is where that answer
/// stands now, kept in a `ValueNotifier`: idle → loading → success / failure.
/// One value instead of separate `isLoading` / `error` / data notifiers:
/// - an action: `ResultState<void>` — idle → loading → success / failure;
/// - live data: `ResultState<List<Note>>` — loading → success(notes) / failure.
sealed class ResultState<T> {
  const ResultState();

  /// Nothing has started yet.
  static const ResultState<Never> idle = IdleResultState<Never>();

  /// The action runs, or the first data has not arrived yet.
  static const ResultState<Never> loading = LoadingResultState<Never>();

  /// Succeeded with [value].
  const factory ResultState.success(T value) = SuccessResultState<T>;

  /// Failed with a human-readable [message] for the UI.
  const factory ResultState.failure(String message) = FailureResultState<T>;

  /// The state of a finished operation: success with its value or failure with its error.
  ///
  /// Every call creates a new instance, so the same failure twice still notifies listeners.
  factory ResultState.of(Result<T> result) => result.when(success: SuccessResultState<T>.new, failure: FailureResultState<T>.new);

  /// Whether nothing has started yet.
  bool get isIdle => this is IdleResultState<T>;

  /// Whether the action runs or the first data has not arrived yet.
  bool get isLoading => this is LoadingResultState<T>;

  /// Whether it succeeded.
  bool get isSuccess => this is SuccessResultState<T>;

  /// Whether it failed.
  bool get isFailure => this is FailureResultState<T>;

  /// Calls the function for the current state; [success] gets the value, [failure] the message.
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T value) success,
    required R Function(String message) failure,
  }) =>
      switch (this) {
        IdleResultState<T>() => idle(),
        LoadingResultState<T>() => loading(),
        SuccessResultState<T>(:final T value) => success(value),
        FailureResultState<T>(:final String message) => failure(message),
      };
}

/// Nothing has started yet; use [ResultState.idle].
final class IdleResultState<T> extends ResultState<T> {
  /// Creates the state.
  const IdleResultState();
}

/// The action runs, or the first data has not arrived yet; use [ResultState.loading].
final class LoadingResultState<T> extends ResultState<T> {
  /// Creates the state.
  const LoadingResultState();
}

/// Succeeded with [value].
final class SuccessResultState<T> extends ResultState<T> {
  /// Your data: the loaded list, the created item, or `null` for `ResultState<void>`.
  final T value;

  /// Creates a successful state with [value].
  const SuccessResultState(this.value);
}

/// Failed with [message].
final class FailureResultState<T> extends ResultState<T> {
  /// Human-readable error message.
  final String message;

  /// Creates a failed state with [message].
  const FailureResultState(this.message);
}
