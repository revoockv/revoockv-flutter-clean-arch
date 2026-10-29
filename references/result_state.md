# ResultState — one state for actions and live data

`ResultState<T>` is the **only** sealed state for "a result that is not here yet, is here, or failed": a user action in a controller and live data in a repository.

- `Future<Result<T>>` — **one answer** to one call: success or failure.
- `ResultState<T>` — **where that answer stands now**, kept in a `ValueNotifier`: `idle` → `loading` → `success(value)` / `failure(message)`. `ResultState.of(result)` turns the answer into the state.
 Do not create `LoadState`, `ActionState`, `NotesState` copies of it — put your own data into `T`.

| State | An action (`ResultState<void>`) | Live data (`ResultState<List<Note>>`) |
|---|---|---|
| `ResultState.idle` | nothing started yet | (not used) |
| `ResultState.loading` | the action runs | waiting for the first event |
| `ResultState.success(value)` | the action succeeded | the data — `value` is yours |
| `ResultState.failure(message)` | the action failed | the stream reported an error |

`lib/core/domain/entities/result_state.dart`

```dart
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
```

It lives in `core/domain/entities/` next to `Result`: repositories expose it through domain interfaces, controllers use it in presentation.

## Read it like `Result`

- `state.isLoading`, `state.isSuccess`, `state.isFailure`, `state.isIdle` — "what is it now?"
- the value or the message — a `switch` over the subclasses, or `state.when(idle: …, loading: …, success: …, failure: …)` with private methods.
- `ResultState.of(result)` turns a finished `Result<T>` into `success` / `failure`.

## Action — in a controller

```dart
final class NotesController extends ValueNotifier<ResultState<void>> {
  NotesController({required this._add, …}) : super(ResultState.idle);

  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (value.isLoading) return false;          // a double tap does not run it twice
    value = ResultState.loading;
    final Result<void> result = await action();
    if (_isDisposed) return false;
    value = ResultState.of(result);              // success / a new failure instance
    return result.isSuccess;
  }
}
```

Full code: `references/controllers.md`, `assets/example_app/lib/features/notes/presentation/controllers/notes_controller.dart`.

## Live data — in a repository

A repository that mirrors a stream starts with `loading`, sets `success` on every event and `failure` on a stream error — the UI can tell "loading", "empty" and "could not load" apart:

```dart
final ValueNotifier<ResultState<List<Note>>> _notes =
    ValueNotifier<ResultState<List<Note>>>(ResultState.loading);

void _onNotes(List<NoteModel> models) {
  _notes.value = ResultState.success(models.map(_toEntity).toList());
}

void _onError(Object error) {
  _logger.e('$_watchFailureLog$error');                   // technical details → logger
  _notes.value = const ResultState.failure(_loadFailedMessage);   // human-readable → UI
}

@override
ValueListenable<ResultState<List<Note>>> watchNotes() => _notes;
```

## UI — `switch` over the state

```dart
final ResultState<List<Note>> notes = watch(watchNotesUseCase()).value;

return switch (notes) {
  IdleResultState<List<Note>>() || LoadingResultState<List<Note>>() =>
    const Center(child: CircularProgressIndicator()),
  FailureResultState<List<Note>>(:final String message) => Center(child: Text(message)),
  SuccessResultState<List<Note>>(:final List<Note> value) when value.isEmpty =>
    const Center(child: Text(_emptyText)),
  SuccessResultState<List<Note>>(:final List<Note> value) => ListView(…),
};
```

The `switch` is exhaustive: every state is handled.

## Rules

- **One type for every such state.** A domain state with its own meaning (`AuthState`: signed in / signed out) stays its own sealed class; "loading / data / error" is always `ResultState<T>`.
- **A failure from a controller is a new instance** (`ResultState.of(result)`, `ResultState.failure(message)` with a runtime message): a `ValueNotifier` notifies only when the value changes, so the same error twice shows twice. A `const` failure (`const ResultState.failure(_loadFailedMessage)` in a repository) is one shared instance — fine for a state, not for a repeated event.
- `idle` / `loading` are typed `ResultState<Never>`, so they fit any `ResultState<T>`.
