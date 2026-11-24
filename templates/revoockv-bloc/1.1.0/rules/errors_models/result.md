# Result (required)

Use a `Result<T>` type for success/failure instead of throwing for expected failures.

Canonical location:
- `lib/core/domain/entities/result.dart`

Rules:
- Commands (sign-in, delete, save) return `Result<void>` and succeed with the shared `Result.ok`.
- Queries return `Result<T>` and succeed with `Result.success(value)` — the value is required and non-nullable.
- Failures carry a human-readable `String` for the UI. Technical details (`e.toString()`, stack traces) go to the logger, never into the `Result`.
- Use `const` whenever all arguments are compile-time constants: `Result.ok`, `const Result.failure(_signInFailedMessage)`.
- Data layer may throw internally; the repository converts **exceptions** to `Result.failure` with `on Exception catch` — never a bare `catch (e)`, so programming errors (`TypeError`, `StateError`) stay visible.
- Use cases pass the repository `Result` through — no try/catch.

## Implementation

- `example/lib/core/domain/entities/result.dart`

`Result.ok` is typed `Result<void>`, so returning it from a function that promises `Result<User>` does not compile, and `Result.success()` without a value does not compile either.

## Repository

```dart
/// Message shown when sign-in fails.
static const String _signInFailedMessage = 'Could not sign in';

static const String _signInSuccessLog = 'SignIn: success — user signed in';
static const String _signInFailureLog = 'SignIn: failure — ';
static const String _loadUserSuccessLog = 'LoadUser: success — user ';
static const String _loadedLog = ' loaded';
static const String _loadUserFailureLog = 'LoadUser: failure — ';

@override
Future<Result<void>> signIn() async {
  try {
    await _dataSource.signIn();
    _logger.i(_signInSuccessLog);
    return Result.ok;
  } on Exception catch (e) {
    _logger.e('$_signInFailureLog$e');
    return const Result.failure(_signInFailedMessage);
  }
}

@override
Future<Result<User>> loadUser() async {
  try {
    final UserModel model = await _dataSource.loadUser();
    _logger.i('$_loadUserSuccessLog${model.id}$_loadedLog');
    return Result.success(model.toEntity());
  } on Exception catch (e) {
    _logger.e('$_loadUserFailureLog$e');
    return const Result.failure(_loadUserFailedMessage);
  }
}
```

## Usage

Only success or failure matters (commands):

```dart
final Result<void> result = await signInUseCase();
if (result.isFailure) {
  // ...
}
```

The value or the error is needed — `when` with private methods (no inline closures, no `!`):

```dart
final Result<User> result = await loadUserUseCase();
result.when(success: _showUser, failure: _showError);

void _showUser(User user) { /* user is non-nullable */ }
void _showError(String error) { /* human-readable text */ }
```

Blocs and cubits turn a `Result` into a state with a `switch` (`SuccessResult(:final value)` / `FailureResult(:final error)`); widgets never see a `Result` — see `rules/state/blocs.md`.

`isSuccess` / `isFailure` are plain `bool` getters: Dart does not narrow the type after them, so use `when` (or a `switch`) whenever the value or the error is read. There are no nullable `value` / `errorMessage` getters on `Result`.
