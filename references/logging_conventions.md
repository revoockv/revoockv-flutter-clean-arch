# Logging conventions (logger package)

- Add `logger` to `pubspec.yaml` dependencies — the pinned version is in `SKILL.md` → "Packages".
- Register Logger in core presentation DI: `lib/core/presentation/di/core_di.dart`.
- Core DI is called first in `registerAndInit()` (in `lib/di.dart`) before any feature DI — see `references/di_patterns.md`:
  ```dart
  Future<void> registerAndInit() async {
    await di.reset();
    registerAndInitCore();
    registerAndInitAuth();
    registerAndInitSong();
    await di.allReady();
  }
  ```
- `registerAndInitCore()` registers Logger as an **eager** singleton (not lazy):
  ```dart
  void registerAndInitCore() {
    di.registerSingleton<Logger>(Logger());
  }
  ```
- Logger is injected via **constructor parameter** into every repository implementation — never fetched via `di<Logger>()` inside the class.
  ```dart
  final class SongRepositoryImpl implements SongRepository {
    final Logger _logger;
    SongRepositoryImpl({required this._logger});
  }
  ```
- DI files pass Logger from `di` when constructing repositories:
  ```dart
  di.registerSingletonAsync<SongRepository>(
    () => SongRepositoryImpl(
      dataSource: di<SongDataSource>(),   // the SDK (Firebase) lives in the data source, never in the repository
      logger: di<Logger>(),
    ).init(),
    dispose: disposeResource,
  );
  ```
- Log `init()` and `dispose()` of every repository: `AuthRepository init: subscribed to user changes`, `AuthRepository dispose: unsubscribed`.
- Log **every public method** in repository implementations (both success and failure paths):
  - **Success**: log a human-readable description of what happened (not `toString` of the result object).
    Example: `AddSong: success — song "Name" by "Author" added`
  - **Failure**: log the error via `toString`.
    Example: `AddSong: failure — <exception>`
  - **Early returns** (e.g., unauthenticated): log as a warning (`_logger.w`) with the reason.
    Example: `AddSong: skipped — user is not signed in`
  - **Init/startup**: log when subscriptions begin.
    Example: `Song repository init: subscribed to songs for user <id>`
- Log format: `MethodName: <status> — <description>`
  - Status: `starting`, `success`, `failure` (an exception), `skipped` (an early return)
  - Include relevant identifiers (IDs, names, sizes) in the description.
- Log text is a private `static const` of the class, like any other string (linter: `magic_strings`). In an interpolated message every text piece between the values is a constant; the call only joins constants and values:
  ```dart
  static const String _addSuccessLog = 'AddSong: success — song ';
  static const String _byLog = ' by ';
  static const String _addFailureLog = 'AddSong: failure — ';

  _logger.i('$_addSuccessLog$name$_byLog$author');
  _logger.e('$_addFailureLog$e');
  ```
  Name log constants `_<what>Log`. The same applies to `throw` messages and `assert` messages.
