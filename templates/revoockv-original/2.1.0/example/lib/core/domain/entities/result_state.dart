import 'result.dart';

/// The current state of a result that changes over time — of a user action or of
/// live data — with your own data of type [T] on success and a failure of type [F].
///
/// `Future<Result<T, F>>` is one answer to one call; [ResultState] is where that answer
/// stands now, kept in a `ValueNotifier`: idle → loading → success / failure.
/// One value instead of separate `isLoading` / `error` / data notifiers:
/// - an action: `ResultState<void, NoteFailure>` — idle → loading → success / failure;
/// - live data: `ResultState<List<Note>, NoteFailure>` — loading → success(notes) / failure.
sealed class ResultState<T, F> {
  const ResultState();

  /// Nothing has started yet.
  static const ResultState<Never, Never> idle = IdleResultState<Never, Never>();

  /// The action runs, or the first data has not arrived yet.
  static const ResultState<Never, Never> loading = LoadingResultState<Never, Never>();

  /// Succeeded with [value].
  const factory ResultState.success(T value) = SuccessResultState<T, F>;

  /// Failed with [failure]; the presentation layer turns it into text.
  const factory ResultState.failure(F failure) = FailureResultState<T, F>;

  /// The state of a finished operation: success with its value or failure with its failure.
  ///
  /// Every call creates a new instance, so the same failure twice still notifies listeners.
  factory ResultState.of(Result<T, F> result) =>
      result.when(success: SuccessResultState<T, F>.new, failure: FailureResultState<T, F>.new);

  /// Whether nothing has started yet.
  bool get isIdle => this is IdleResultState<T, F>;

  /// Whether the action runs or the first data has not arrived yet.
  bool get isLoading => this is LoadingResultState<T, F>;

  /// Whether it succeeded.
  bool get isSuccess => this is SuccessResultState<T, F>;

  /// Whether it failed.
  bool get isFailure => this is FailureResultState<T, F>;

  /// Calls the function for the current state; [success] gets the value, [failure] the failure.
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T value) success,
    required R Function(F failure) failure,
  }) =>
      switch (this) {
        IdleResultState<T, F>() => idle(),
        LoadingResultState<T, F>() => loading(),
        SuccessResultState<T, F>(:final T value) => success(value),
        FailureResultState<T, F>(failure: final F reason) => failure(reason),
      };
}

/// Nothing has started yet; use [ResultState.idle].
final class IdleResultState<T, F> extends ResultState<T, F> {
  /// Creates the state.
  const IdleResultState();
}

/// The action runs, or the first data has not arrived yet; use [ResultState.loading].
final class LoadingResultState<T, F> extends ResultState<T, F> {
  /// Creates the state.
  const LoadingResultState();
}

/// Succeeded with [value].
final class SuccessResultState<T, F> extends ResultState<T, F> {
  /// Your data: the loaded list, the created item, or `null` for `ResultState<void, F>`.
  final T value;

  /// Creates a successful state with [value].
  const SuccessResultState(this.value);
}

/// Failed with [failure].
final class FailureResultState<T, F> extends ResultState<T, F> {
  /// What went wrong.
  final F failure;

  /// Creates a failed state with [failure].
  const FailureResultState(this.failure);
}
