---
name: revoockv-flutter-clean-arch
description: Enforce and implement revoockv's Flutter clean architecture using GetIt + watch_it (ValueNotifier-based reactive state). Use when the user asks to create a new feature, refactor an existing project/feature, migrate from Riverpod/Bloc/streams to watch_it + ValueNotifier, add DI modules per feature/subfeature (register by type + use case getters), create data models (DTO) with mapping to domain entities, or build minimal-rebuild UI with watch(watch<Name>UseCase()).value.
metadata:
  version: 0.8.0
  author: revoockv
---

# revoockv Flutter Clean Architecture (GetIt + ValueNotifier + watch_it)

This skill is strict. If any architectural decision is unclear, copy the patterns from `references/feature_template_auth.md` (or the runnable `assets/example_app/`) and adapt naming only.

## Reference app

`assets/example_app/` is a neutral notes app built with every rule of this skill: core, one feature on all layers, DI, a controller with `ResultState` + `createOnce` + `registerHandler`, and tests on every layer. It passes `flutter analyze`, `flutter test` and the linter with `--strict`. When the docs and your memory disagree, the example app wins.

## Packages (pinned versions)

```yaml
environment:
  sdk: ^3.12.0
dependencies:
  get_it: ^9.3.0
  logger: ^2.8.0
  uuid: ^4.6.0
  watch_it: ^2.5.0
dev_dependencies:
  flutter_lints: ^6.0.0
```

Only an app that serves its use cases over HTTP adds `relic: ^1.2.0` (`references/serving_http.md`).

The source of truth is `assets/example_app/pubspec.yaml`. Before adding packages to a project, run `python3 <skill_base>/scripts/check_versions.py`: it compares the pins with the latest versions on pub.dev. When something is outdated, tell the user; `--update` bumps the pins in the example and the docs, then `scripts/selfcheck.py` must pass before the new versions are used.

## Scripts

| Script | What it does |
|---|---|
| `scripts/dart_clean_arch_linter.py` | Architecture linter — run after every change (below) |
| `scripts/init_feature.py --core` / `--feature <name>` | Creates the full folder skeleton (with `.gitkeep`), copies the verified core files from the example app, creates `lib/di.dart` and feature DI stubs |
| `scripts/check_versions.py` | Pinned versions vs pub.dev (`--strict`, `--update`) |
| `scripts/selfcheck.py` | Checks the skill itself: linter tests, versions, example app (analyze, test, lint), and compiles the code from the docs. Run it after editing this skill |

## Must-read references (load these when implementing)

- DI patterns: `references/di_patterns.md` — `registerAndInit<Feature>()`, lazy/async registration, `init()`/`dispose()`, when to dispose, `registerAndInit()`
- Logging conventions: `references/logging_conventions.md` — logger setup, constructor injection, log format
- Dartdoc standard: `references/dartdoc_standard.md` — required documentation coverage
- Folder structure: `references/folder_structure.md`
- Result: `references/result.md`
- ResultState (one state for actions and live data — loading / success(value) / failure): `references/result_state.md`
- Models mapping: `references/models_mapping.md`
- Controllers (UI logic only, when they are needed): `references/controllers.md`
- Imports conventions: `references/imports.md`
- Use case naming: `references/use_case_naming.md`
- Reactive state: `references/reactive_state_syntax.md` — `watch`, `registerHandler`, the order rule, derived state
- Testing: `references/testing.md` — what to test on each layer, fakes, widget tests with a test DI per feature and fake data sources
- Git rules: `references/git_rules.md` — universal branch strategy, commit message format, tagging conventions
- Serving use cases over HTTP (an `api_server` feature with Relic routes, token middleware, on/off switch): `references/serving_http.md`

## Quick navigation

Use `DECISIONS.md` to find the right reference file or pattern without reading all references. It maps "you need X → use pattern Y" across architecture, state, DI, data, UI, and conventions.


## Automated linting (always run after changes)

The linter script lives in the skill's `scripts/` folder. Never copy the script into the project.

**Default target = the whole Flutter project.** When the user does not name a feature, run the linter with no path argument — it defaults to `lib` and walks every feature. Only when the user gives an exact feature path do you narrow the target to that single feature folder.

```bash
# Default — run over the WHOLE project (all features under lib/), no path argument needed
python3 <skill_base>/scripts/dart_clean_arch_linter.py

# Exact feature — run only over one feature when the user names it
python3 <skill_base>/scripts/dart_clean_arch_linter.py <project_path>/lib/features/<feature>

# Strict mode — exits 1 on violations (for CI / pre-commit)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --strict

# Subset of rules
python3 <skill_base>/scripts/dart_clean_arch_linter.py --rules naming_file,naming_class,inline_callbacks

# JSON output (for programmatic consumption)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --json

# Ignore specific rules (only when the user explicitly requests)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --ignore magic_numbers,magic_strings
```

The `path` positional argument is optional: omit it (or pass `lib`) for the whole project, or pass a single feature folder to narrow the scope. All flag combinations (`--strict`, `--rules`, `--json`, `--ignore`) work with either target.

**29 rules:** `naming_file`, `naming_class`, `magic_numbers`, `magic_strings`, `magic_colors`, `widget_helpers`, `inline_callbacks`, `import_violation`, `setstate_usage`, `stateful_no_lifecycle`, `dartdoc_public`, `no_state_in_di`, `widget_stateless`, `watching_widget`, `no_controller_in_ui`, `static_const_order`, `no_build_return`, `folder_naming`, `async_gap_context_mounted`, `widget_key_parameter`, `controller_lifecycle`, `widget_methods`, `stateless_with_controllers`, `static_const_in_state_class`, `magic_numbers_in_layout`, `theme_import`, `value_listenable_exposure`, `watch_order`, `show_imports`.

All rules are enabled by default. Only disable a rule with `--ignore` when the user explicitly requests it.

## Target project structure

See `references/folder_structure.md`.

## Layer responsibilities

- Domain: entities (sealed or simple), repo interfaces, use cases (no tech details).
- Data: data_sources/services (Streams allowed), models/DTO mapping, repository implementations that own a private `ValueNotifier<T>` and expose it outward only as `ValueListenable<T>`.
- Presentation: pages/widgets + DI + getters + optional controllers. A controller holds UI logic only and never touches the data layer; domain/data state comes from `watch…UseCase` getters (`references/controllers.md`).

## Workflow: choose the operation

### A) Create a new feature

1. Create folder skeleton under `lib/features/<feature>/...` (see `references/folder_structure.md`).
2. Implement Domain first:
   - entities
   - repository interface
   - use cases
3. Implement Data:
   - data_sources/services (Streams allowed)
   - models (DTO) in `data/models/` with Model↔Entity mapping
   - repository implementation: private `ValueNotifier<T>` field, public `ValueListenable<T> watch<Name>()` returning that same field
   - startup work in `Future<Impl> init()` that returns `this`; classes owning subscriptions/controllers/connections implement `DisposableResource`
4. Presentation DI (`references/di_patterns.md`):
   - one function `registerAndInit<Feature>()` in `<feature>_di.dart`, using `di` from watch_it
   - register bottom-up: data sources → repositories → use cases; `registerLazySingleton` wherever possible, `registerSingletonAsync(() => Impl(...).init())` for startup work; `dispose: disposeResource` for every `DisposableResource`
   - `lib/di.dart` → `registerAndInit()` calls every `registerAndInit<Feature>()` and awaits `di.allReady()`
   - expose every use case as a top-level getter in `<feature>_getters.dart` that returns the use case object (e.g., `WatchSongsUseCase get watchSongsUseCase => di<WatchSongsUseCase>();`)
   - the getter name without parentheses is the use case; with parentheses (`addSongUseCase()`) it invokes `call()`
5. UI:
    - small widgets, tight watch scopes
    - **Reading state:** domain/data state — `final ResultState<List<Song>> songs = watch(watchSongsUseCase()).value;`; UI state of a controller — `final bool isLoading = watch(controller).value.isLoading;`. `watch()` subscribes and returns the `ValueListenable` itself, so `.value` follows it.
    - `watchValue()` and `watchIt()` are not used in widgets (linter: `watching_widget`).
    - **Reacting to state** (navigation, snackbar, dialog) uses `registerHandler(target: watch<Name>UseCase(), handler: _onX)` (or `target: controller` — a UI controller) — the handler is a private method `(BuildContext context, T value, void Function() cancel)` and runs only on a change (`executeImmediately: true` for the first value too). Never put these into `build()`. Which screen a state needs (signed out → sign-in) is not a reaction: `watch` + `switch` over the sealed state picks the widget (`AuthGateWidget`).
    - **The order rule:** `watch()` / `registerHandler()` / `createOnce()` are called unconditionally at the top of `build()` — never inside `if` / `for` / `switch` or callbacks (linter: `watch_order`).
    - **`WatchingWidget` rule:** Only extend `WatchingWidget` (or `WatchingStatefulWidget`) when the widget calls `watch()` / `registerHandler()` — on a watch use case (`watch(watchSongsUseCase())`) or on its controller (`watch(controller)`), or owns a controller with `createOnce()`. Watch use cases start with `watch` and return `ValueListenable<T>` (e.g., `watchSongsUseCase`, `watchCurrentSessionUseCase`).
    - **Mandatory:** `watch()` / `registerHandler()` / `createOnce()` only work inside `WatchingWidget` / `WatchingStatefulWidget`; in `StatelessWidget` / `StatefulWidget` they throw a runtime assertion error.
    - **Action use cases** (e.g., `addSongUseCase`, `deleteSongUseCase`, `updateSongUseCase`) return `Future<Result>`. When the UI shows nothing around the action, a private method of the widget calls the use case directly (`void _onSignOutPressed() { signOutUseCase(); }`) — no controller. When the UI shows progress, the error or form state, that UI logic goes into a controller — a `ValueNotifier<ResultState<void>>` (`core/domain/entities/result_state.dart`, `references/result_state.md`) that gets the use case through its constructor (`SignInController(signIn: signInUseCase.call)`) and knows nothing about DI, like `TextEditingController`. The owner is a `WatchingWidget` that creates it with `createOnce(_createController, dispose: _disposeController)` and reacts to failures with `registerHandler(target: controller, handler: _onActionChanged)` — no rebuild; only the lowest widget that shows progress calls `watch(controller).value.isLoading` — `references/controllers.md`.
    - **One state — one notifier:** the state of one thing is one value (a sealed class, an enum, `ResultState`), not several notifiers; split only parts that change independently.
    - If a widget extends `WatchingWidget` without one of these calls, or calls them outside a Watching widget, the linter flags a `watching_widget` violation.
    - `ValueNotifier` never leaks outward: domain, public repository members and getters use `ValueListenable<T>` (linter: `value_listenable_exposure`). See `references/reactive_state_syntax.md`.

     - **Deepest widgets must be dumb:** The deepest (most nested) widgets in the widget tree — buttons, list items, tiles, dialog actions — must know nothing about use cases, repositories, or business logic. They receive data as constructor parameters and expose callbacks (`onPressed`, `onTap`, `onChanged`). All validation, use case calls, and state management belong in the closest parent widget: the `WatchingWidget` that owns the controller (`createOnce`), or — when there is no UI logic — the parent widget that calls the use case in a private method. The deepest widgets should be as simple as possible: they render UI and forward events.

Golden reference:
- `references/feature_template_auth.md`

### B) Refactor an existing feature

Use:
- `references/feature_template_auth.md`
- Run `scripts/dart_clean_arch_linter.py` after refactoring to verify all rules pass.

### C) Migrate from Riverpod/Bloc/Streams

- Keep Streams inside data sources where the library uses Streams.
- Repositories hold a private `ValueNotifier<T>` and expose `ValueListenable<T>` outward.
- UI uses `watch(watch<Name>UseCase()).value` inside `WatchingWidget` from watch_it.

Use:
- `references/feature_template_auth.md`

## Critical Notes

### Result — `Result.ok`, `const`, `when`

Full contract: `references/result.md` (`lib/core/domain/entities/result.dart`).

- Commands return the shared `Result.ok`; queries return `Result.success(value)` with a required value.
- `Result.success` / `Result.failure` are `const factory` constructors — use `const` whenever all arguments are constants (`const Result.failure(_signInFailedMessage)`). Enable `prefer_const_constructors` in `analysis_options.yaml`.
- `isSuccess` / `isFailure` answer "did it work?"; read the value or error with `result.when(success: _onX, failure: _onError)`.
- Failure text is human-readable; raw exceptions go to the logger. Repositories use `on Exception catch`, never a bare `catch (e)`.

### Private Named Parameters

Inject dependencies with private named parameters: `AuthRepositoryImpl({required this._dataSource, required this._logger});` — callers still write `dataSource:` / `logger:`, and `flutter analyze` (`prefer_initializing_formals`) asks for this form. It needs `sdk: ^3.12.0` in `pubspec.yaml`; on an older SDK use an initializer list: `({required AuthDataSource dataSource}) : _dataSource = dataSource`.

### Const Constructors + Asserts

A `const` constructor may validate its parameters with `assert` in the initializer list. For a `const` call the asserts are checked at compile time (an invalid constant does not compile), for a non-`const` call at runtime in debug builds. One constructor is enough — no separate `_internal` constructor for const defaults:

```dart
final class ChatSettingsEntity {
  /// Model used when the user has not chosen one.
  static const String _defaultModel = 'Qwen3.6-35B-A3B-4bit';

  /// Default sampling temperature.
  static const double _defaultTemperature = 0.7;

  /// Settings of a new chat.
  static const ChatSettingsEntity defaultSettings = ChatSettingsEntity(selectedModel: _defaultModel);

  static const String _emptyModelMessage = 'selectedModel must not be empty';
  static const String _temperatureRangeMessage = 'temperature must be between 0.0 and 1.0';

  /// Name of the selected model.
  final String selectedModel;

  /// Sampling temperature, 0.0–1.0.
  final double temperature;

  /// How the chat sends requests.
  final ChatMode chatMode;

  /// Creates settings; asserts run at compile time for `const` calls.
  const ChatSettingsEntity({
    required this.selectedModel,
    this.temperature = _defaultTemperature,
    this.chatMode = ChatMode.oneCommand,
  })  : assert(selectedModel != '', _emptyModelMessage),
        assert(temperature >= 0.0 && temperature <= 1.0, _temperatureRangeMessage);
}
```

`selectedModel != ''` instead of `selectedModel.isNotEmpty`: a getter call is not a constant expression, so `isNotEmpty` would break the `const` call.

### Constants — owning class, or core when shared

Never declare simple constants at file top level. Two places only:

**1. Used by one widget/class → private `static const` of that class:**

```dart
class VideoPlayerErrorWidget extends StatelessWidget {
  /// Size of the error icon in the error view.
  static const double _errorIconSize = 32;

  /// Label of the retry button.
  static const String _retryButtonLabel = 'Retry';
```

**2. Shared by several features (spacing, sizes, colors) → public `static const` of `AppTheme` in core:**

`lib/core/presentation/theme.dart`

```dart
import 'package:flutter/material.dart';

/// Values shared by more than one feature: spacing, sizes, colors.
///
/// A value used by a single widget stays a private `static const` of that widget.
final class AppTheme {
  /// Small gap between related elements.
  static const double spacingSmall = 8;

  /// Default padding of screens and cards.
  static const double spacingMedium = 16;

  /// Large gap between sections.
  static const double spacingLarge = 24;

  /// Seed color of the app color scheme.
  static const Color seedColor = Colors.indigo;

  const AppTheme._();
}
```

Use it as `AppTheme.spacingMedium` (import `package:<your_app>/core/presentation/theme.dart`). There are no per-feature theme files.

Rules:
- A value used by one class stays private in that class — do not move it to core "just in case".
- The same private constant (type, name, value) in two features is a shared value → move it to `AppTheme` (linter: `theme_import`).
- A private spacing constant (`_padding`, `_spacing`, `_gap`, `_margin`, `_inset`) with a value that `AppTheme` already has must use `AppTheme` (linter: `theme_import`).
- `magic_strings` and `magic_numbers` treat file-top-level `const Type _name = ...` as violations — only class-member `static const` is accepted.

### Magic Strings — Every Layer, No Exemptions

The `magic_strings` rule applies to every layer, the data layer included. JSON keys, CLI arguments, API parameter names, file extensions, separators and enum labels are private `static const` members of the class that uses them, like UI text and error messages:

```dart
final class NoteModel {
  /// JSON key of the note id.
  static const String _idKey = 'id';

  /// JSON key of the note text.
  static const String _textKey = 'text';

  NoteModel.fromJson(Map<String, dynamic> json)
    : id = json[_idKey] as String,
      text = json[_textKey] as String;
}

enum HistoryKind {
  image(_imageLabel),
  video(_videoLabel);

  static const String _imageLabel = 'Images';
  static const String _videoLabel = 'Video';

  /// Shown in the UI.
  final String label;

  const HistoryKind(this.label);
}
```

Log messages, `throw` and `assert` messages are no exception. In an interpolated string every text piece between the values is a constant; the string only joins constants and values:

```dart
static const String _searchSuccessLog = 'SearchJobs: success — ';
static const String _jobsToLog = ' job(s) → ';

_logger.i('$_searchSuccessLog${report.total}$_jobsToLog${report.path}');
```

Accepted by the linter: literals inside a `static const` / `static final` declaration (also when it spans several lines), directives (`import`, `export`, `part`), and pieces that are only whitespace or a number. A literal equal to an existing constant is still a violation — use the constant.
