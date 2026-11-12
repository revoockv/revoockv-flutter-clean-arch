# Logging conventions (logger package)

- Add `logger` to `pubspec.yaml` dependencies — the pinned version is in `rules/packages/packages.md`.
- `CoreProvidersWidget` (`lib/core/presentation/di/core_di.dart`) provides one `Logger` above every feature
  (`rules/di/providers.md`); tests pass a silent one (`createLogger`).
- Logger is injected via **constructor parameter** into every repository implementation; its provider reads it:
  `NotesRepositoryImpl(dataSource: context.read<NotesDataSource>(), logger: context.read<Logger>())`.
- Log a stream error of a repository where it becomes a failure: `WatchNotes: failure — <error>`.
- Log **every public method** in repository implementations (both success and failure paths):
  - **Success**: log a human-readable description of what happened (not `toString` of the result object).
    Example: `AddSong: success — song "Name" by "Author" added`
  - **Failure**: log the error via `toString`.
    Example: `AddSong: failure — <exception>`
  - **Early returns** (e.g., unauthenticated): log as a warning (`_logger.w`) with the reason.
    Example: `AddSong: skipped — user is not signed in`
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
