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

`lib/core/domain/entities/result.dart`

```dart
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
```

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

In widgets, when the UI shows the progress or the error of an action, the `Result` goes through a UI controller: the controller (a `ValueNotifier<ResultState<void>>`) calls the use case and sets `ResultState.failure(message)`, the owner shows it with `registerHandler` — see `references/controllers.md` → "With a controller". When nothing is shown, the widget calls the use case directly ("Without a controller").

`isSuccess` / `isFailure` are plain `bool` getters: Dart does not narrow the type after them, so use `when` (or a `switch`) whenever the value or the error is read. There are no nullable `value` / `errorMessage` getters on `Result`.
