# ResultState — one state for actions and live data

`ResultState<T, F>` is the **only** sealed state for "a result that is not here yet, is here, or failed": a user action in a controller and live data in a repository.

- `Future<Result<T, F>>` — **one answer** to one call: success or failure.
- `ResultState<T, F>` — **where that answer stands now**, kept in a `ValueNotifier`: `idle` → `loading` → `success(value)` / `failure(failure)`. `ResultState.of(result)` turns the answer into the state.
 Do not create `LoadState`, `ActionState`, `NotesState` copies of it — put your own data into `T`.

| State | An action (`ResultState<void, NoteFailure>`) | Live data (`ResultState<List<Note>, NoteFailure>`) |
|---|---|---|
| `ResultState.idle` | nothing started yet | (not used) |
| `ResultState.loading` | the action runs | waiting for the first event |
| `ResultState.success(value)` | the action succeeded | the data — `value` is yours |
| `ResultState.failure(failure)` | the action failed | the stream reported an error |

- `example/lib/core/domain/entities/result_state.dart`

It lives in `core/domain/entities/` next to `Result`: repositories expose it through domain interfaces, UI controllers hold it in presentation.

## Read it like `Result`

- `state.isLoading`, `state.isSuccess`, `state.isFailure`, `state.isIdle` — "what is it now?"
- the value or the failure — a `switch` over the subclasses, or `state.when(idle: …, loading: …, success: …, failure: …)` with private methods.
- `ResultState.of(result)` turns a finished `Result<T, F>` into `success` / `failure`.

## Action — the owner widget calls, the controller holds

```dart
// NotesController holds: final ValueNotifier<ResultState<void, NoteFailure>> addingStateController = …;
Future<void> _onAddPressed(NotesController notesController) async {
  final ValueNotifier<ResultState<void, NoteFailure>> addingStateController = notesController.addingStateController;
  if (addingStateController.value.isLoading) return;   // a double tap does not run it twice
  addingStateController.value = ResultState.loading;

  final Result<void, NoteFailure> result = await addNoteUseCase(notesController.noteTextController.text);
  if (notesController.isDisposed) return;

  addingStateController.value = ResultState.of(result); // success / a new failure instance
}
```

Full code: `rules/state/controllers.md`, `example/lib/features/notes/presentation/pages/notes_page.dart`.

## Live data — in a repository

A repository that mirrors a stream starts with `loading`, sets `success` on every event and `failure` on a stream error — the UI can tell "loading", "empty" and "could not load" apart:

```dart
final ValueNotifier<ResultState<List<Note>, NoteFailure>> _notes =
    ValueNotifier<ResultState<List<Note>, NoteFailure>>(ResultState.loading);

void _onNotes(List<NoteModel> models) {
  _notes.value = ResultState.success(models.map(_toEntity).toList());
}

void _onError(Object error) {
  _logger.e('$_watchFailureLog$error');                   // technical details → logger
  _notes.value = const ResultState.failure(NoteFailure.load);  // what went wrong → UI
}

@override
ValueListenable<ResultState<List<Note>, NoteFailure>> watchNotes() => _notes;
```

## UI — `switch` over the state

```dart
final ResultState<List<Note>, NoteFailure> notes = watch(watchNotesUseCase()).value;

return switch (notes) {
  IdleResultState<List<Note>, NoteFailure>() || LoadingResultState<List<Note>, NoteFailure>() =>
    const Center(child: CircularProgressIndicator()),
  FailureResultState<List<Note>, NoteFailure>(:final NoteFailure failure) => Center(child: Text(failure.text)),
  SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) when value.isEmpty =>
    const Center(child: Text(_emptyText)),
  SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) => ListView(…),
};
```

The `switch` is exhaustive: every state is handled.

## Rules

- **One type for every such state.** A domain state with its own meaning (`AuthState`: signed in / signed out) stays its own sealed class; "loading / data / error" is always `ResultState<T, F>`.
- **A failure of an action is a new instance** (`ResultState.of(result)`, `ResultState.failure(failure)` without `const`): a `ValueNotifier` notifies only when the value changes, so the same error twice shows twice. A `const` failure (`const ResultState.failure(NoteFailure.load)` in a repository) is one shared instance — fine for a state, not for a repeated event.
- `idle` / `loading` are typed `ResultState<Never, Never>`: `Never` is a subtype of every type, so they fit any `ResultState<T, F>`.
