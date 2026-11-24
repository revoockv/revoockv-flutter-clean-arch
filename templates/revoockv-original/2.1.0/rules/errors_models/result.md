# Result and failures (required)

Use `Result<T, F>` for success/failure instead of throwing for expected failures: `T` is the value, `F` the failure
type of the feature.

Canonical location:
- `lib/core/domain/entities/result.dart` — `example/lib/core/domain/entities/result.dart`

## The failure type

Choose once per app:

| The app | `F` | Text |
|---|---|---|
| in one language, no translations | `TextOnlyFailure` (core) — `example/lib/core/domain/entities/text_only_failure.dart` | in the failure: `const Result.failure(TextOnlyFailure(_addFailedMessage))`, the UI shows `failure.text` |
| with translations | a failure type per feature (below) | in `presentation/l10n` |

`Result<T, F>` is the same in both, so an app moves to translations by replacing `TextOnlyFailure` feature by feature.

### Failure type per feature

- Every feature has its own failure type in `domain/entities/<feature>_failure.dart`:
  - an `enum` when a failure carries nothing — `example/lib/features/notes/domain/entities/note_failure.dart`;
  - a `sealed class` when it carries data the text needs (`UnsupportedSampleRateFailure(hertz)`, `PeerStoppedFailure(deviceName)`).
- A failure says **what went wrong**, never how to say it: no text in domain or data. Technical details
  (`e.toString()`, stack traces) go to the logger, never into the failure.
- Its text lives in presentation: `presentation/l10n/<feature>_failure_text.dart`, an extension with an exhaustive
  `switch` — a new failure without a text does not compile.
  `example/lib/features/notes/presentation/l10n/note_failure_text.dart`.
  - An app in one language returns constants (`String get text`).
  - An app with translations takes the strings of the current language (`String text(Translations t)`), so the
    text follows the language the user picks; the same applies to every other domain value shown as text
    (enum labels, progress steps).
- A use case that passes on a failure of another feature turns it into its own: `result.mapFailure(_toSyncFailure)`.

## Result

- Commands (sign-in, delete, save) return `Result<void, F>` and succeed with the shared `Result.ok`.
- Queries return `Result<T, F>` and succeed with `Result.success(value)` — the value is required and non-nullable.
- `Result.ok` is `Result<void, Never>`: `Never` is a subtype of every type, so it fits any `Result<void, F>`.
- Use `const` whenever all arguments are compile-time constants: `Result.ok`, `const Result.failure(NoteFailure.add)`.
- Data layer may throw internally; the repository converts **exceptions** to `Result.failure` with `on Exception catch`
  — never a bare `catch (e)`, so programming errors (`TypeError`, `StateError`) stay visible.
- Use cases pass the repository `Result` through — no try/catch. A use case may fail by itself (validation):
  `const Result.failure(NoteFailure.emptyText)`.

## Repository

```dart
@override
Future<Result<void, NoteFailure>> addNote(String text) async {
  try {
    final NoteModel model = await _dataSource.add(text);
    _logger.i('$_addSuccessLog${model.id}$_addedLog');
    return Result.ok;
  } on Exception catch (e) {
    _logger.e('$_addFailureLog$e');            // technical details → logger
    return const Result.failure(NoteFailure.add); // what went wrong → UI
  }
}
```

Full code: `example/lib/features/notes/data/repositories/notes_repository_impl.dart`.

## Usage

Only success or failure matters (commands):

```dart
final Result<void, NoteFailure> result = await deleteNoteUseCase(id);
if (result.isFailure) {
  // ...
}
```

The value or the failure is needed — `when` with private methods (no inline closures, no `!`):

```dart
final Result<User, AuthFailure> result = await loadUserUseCase();
result.when(success: _showUser, failure: _showError);

void _showUser(User user) { /* user is non-nullable */ }
void _showError(AuthFailure failure) { /* show failure.text */ }
```

In widgets, the owner widget calls the use case. When the UI shows the progress or the failure of the action, the
widget writes `ResultState.of(result)` into a `<action>StateController` of its UI controller and shows a failure with
`registerHandler` — see `rules/state/controllers.md` → "With a controller". When nothing is shown, the widget just
calls the use case ("Without a controller").

`isSuccess` / `isFailure` are plain `bool` getters: Dart does not narrow the type after them, so use `when` (or a
`switch`) whenever the value or the failure is read. There are no nullable `value` / `failure` getters on `Result`.
