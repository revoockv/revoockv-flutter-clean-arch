# Changelog

All notable changes to this skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [0.8.0] - 2026-10-31

### Added — Serving use cases over HTTP
- New `references/serving_http.md`: an `api_server` feature serves the use cases of other features to devices on the
  same network with Relic — routes over the use cases (taken as functions, like controllers), a token middleware
  (`Authorization: Bearer`, 256-bit token, constant-time check), off by default, stopped on `dispose()`.
- Example app: the `api_server` feature (state, start / stop / check token use cases, `RelicApiServerDataSource`,
  `NotesRoutes`, switch page behind the Wi-Fi button of the notes page) and core JSON helpers
  (`JsonResponses`, `JsonRequests`, `ErrorDto`), with repository, routes (real server on port 0) and page tests.
- Linter 0.7.1: ignored paths — folders and files the linter skips entirely (also in `folder_naming`), listed one per
  line (relative to the project root, globs, `#` comments) in a global `<skill>/.clean_arch_ignore`, a local
  `<project>/.clean_arch_ignore` or `--ignore-paths`. The rules stay those of 0.7.0 (28); the example app lists its
  server folders (`routes/`, `dto/`, `middleware/`) in its `.clean_arch_ignore`.

### Fixed
- Linter: a field of a function type split over lines (`final X Function({ … }) _f;`) is not a public method
  (`dartdoc_public`).
- `check_versions.py` tracks `relic`; `selfcheck.py` compares the `api_server` code of the docs with the example.

## [0.7.0] - 2026-10-29

### Changed (breaking) — State and controllers
- `ResultState<T>` (`lib/core/domain/entities/result_state.dart`): one sealed type for "where a value or an action stands now" — idle / loading / success(value) / failure(message), `ResultState.of(result)`, `isLoading`-style getters and `when`. No per-case state classes; your own data goes into `T`. New `references/result_state.md`.
- Repositories expose `ValueListenable<ResultState<T>>`: `loading` until the first value, `failure` when the stream errors (logged), `success` otherwise. Widgets `switch` over it.
- `references/no_controllers.md` → `references/controllers.md`. A controller is only for UI logic and is self-contained like `TextEditingController`: no DI, no getters, no data layer; use cases are passed in as functions through the constructor; one state is one `ValueNotifier<ResultState<…>>`, not several notifiers.
- A `WatchingWidget` owns its controller with `createOnce(…, dispose: …)`; a `State` is needed only for `AnimationController` / `didUpdateWidget`. `watch()` goes into the lowest widget that needs the value, `registerHandler()` higher up (no rebuild).
- The auth gate is declarative: `watch` + `switch` over the auth state picks the screen. `registerHandler` is for one-off reactions only (snackbar, dialog, navigation); `executeImmediately: true` when the first value counts.

### Changed (breaking) — Data
- Ids are UUID v4 created in the data source (`uuid ^4.6.0`); `add` returns the created model. Repositories no longer count ids.

### Changed — Tests
- Each feature has a test DI in `test/` — a copy of `registerAndInit<Feature>()` with a fake data source; the app code is not changed for tests. `references/testing.md`, `di_patterns.md`.
- Example app: widget tests through the test DI (add/delete, blank note, failed add, load error), controller tests with plain functions, repository tests for loading, unique ids and stream errors.

### Changed — Git
- `hotfix/` branches, `release/<version>` branches (`[RELEASE-x.y.z]`), dependency and CI updates on release branches (no `CHORE` / `BUILD` types), `--no-ff` merges with a message in the commit format, tags on `main`.
- The pre-commit checklist is split into "any project" and "a Flutter project built with this skill".

### Removed
- The session scope for logout (`pushNewScope` / `popScopesTill`) from `di_patterns.md` and `DECISIONS.md`.
- `core/presentation/controllers/action_state.dart` (replaced by `ResultState`).

### Fixed — Linter
- `import_violation`: presentation (except `di/`) must not import `data/` or call `di` / `GetIt`; `controllers/` must not import `di/`, `*_getters.dart`, get_it or watch_it.
- `watching_widget` rewritten: a `WatchingWidget` must call `watch` / `registerHandler` / `createOnce`; a `StatelessWidget`, or the `State` of a plain `StatefulWidget`, calling them is flagged.
- `watch_order` covers `createOnce`; `controller_lifecycle` flags a `WatchingWidget` that creates resources without `createOnce`.
- `naming_file`: `controllers/` allows `_controller.dart` and `_state.dart`.
- `dartdoc_public` rewritten: finds declarations by position (fields, constructors, getters/setters, top-level functions and variables, function-typed fields), skips `@override`, framework members and `main`, private names and private classes, the unnamed constructor of a `sealed` class; an annotation may stand between the comment and the declaration.

### Changed — Docs and scripts
- `SKILL.md`, `widget_rules.md`, `reactive_state_syntax.md`, `reactive_state_patterns.md`, `result.md`, `feature_template_auth.md`, `models_mapping.md`, `dartdoc_standard.md`, `folder_structure.md`, `imports.md`, `di_conventions.md`, `logging_conventions.md`, `DECISIONS.md` updated to the rules above.
- `init_feature.py` copies `result_state.dart`, checks that feature / subfeature names are snake_case, `--subfeature` requires `--feature`.
- `check_versions.py` tracks `uuid`.
- This changelog lists the newest version first.

---

## [0.6.0] - 2026-10-20

### Changed (breaking)
- `magic_strings` applies to the data layer too: JSON keys, CLI arguments, API parameter names, file extensions and enum labels are private `static const` members of the owning class. The "JSON Keys Exemption" in `SKILL.md` is replaced by "Magic Strings — Every Layer, No Exemptions".
- No exemptions for log messages, `throw` / `assert` messages or `print`: their text is a `static const` too (`_<what>Log` for logs).
- Interpolated strings are checked: every text piece between the values is a `static const`; pieces that are only whitespace or a number are fine. Strings inside `${…}` are checked as well.
- `logging_conventions.md`, `result.md`, `di_patterns.md`, the auth template and the example app use log constants.

### Fixed — Linter
- `magic_strings` reads Dart literals with a scanner instead of line by line:
    - lines of a `static const` / `static final` declaration that spans several lines (string concatenation, list and map literals) are no longer flagged;
    - a quote inside `${…}` no longer splits the literal around it (`'${a.join(' ')}'` used to report `'}'`);
    - comments are skipped by the scanner, so a line with `//` inside a string (`'https://…'`) is checked again.
- `magic_strings` no longer accepts an inline literal just because a constant with the same value exists in the file.
- Raw strings (`r'\$x'`) are not treated as interpolated.
- `magic_numbers` ignores numbers inside string literals and comments, and every line of a `static const` / `static final` declaration that spans several lines.
- `magic_numbers` does not take record fields (`reply.$3`) for numbers.
- `theme_import` compares a private spacing constant only with the spacing constants of `AppTheme` (not with a radius or a border width of the same value).
- `dartdoc_public` does not ask for documentation on `@override` members (they inherit it from the interface).
- `no_state_in_di` also catches the project's own state classes: anything that extends or mixes in `ValueNotifier` / `ChangeNotifier` / `ValueListenable` / `Listenable` (also through another class), registered or read by type (`register…<T>`, `di<T>`) or by instance (`register…(T(…))`, `T.new`). Before, only `ValueNotifier<…>` written out was caught, so a `SettingsController extends ValueNotifier<…>` in GetIt went unnoticed.
- `no_controller_in_ui` counts the `ValueNotifier` / `TextEditingController` / `FocusNode` a file creates, not every mention (a controller received through the constructor is owned elsewhere).
- `controller_lifecycle` checks each `StatelessWidget` on its own: a `ValueNotifier` owned by the `State` class in the same file no longer flags the file's other widgets.

### Added
- `MagicStringsTest` and `LinterFixesTest` in `tests/test_linter.py`.

---

## [0.5.0] - 2026-10-20

### Changed (breaking)
- Reactive state is exposed outward only as `ValueListenable<T>`: repository interfaces, watch use cases and getters. `ValueNotifier<T>` stays a private field of the repository implementation.
- The only canonical way to read state in a widget is `watch(watch<Name>UseCase()).value`. `watchValue()` / `watchIt()` are no longer used in widgets.
- Getters return use case objects (`WatchSongsUseCase get watchSongsUseCase`); calling them with `()` invokes `call()`.
- `feature_template_auth.md`: ValueListenable contract, watch use case, use case DI registration, getters file, `AuthStatusWidget` rewritten to the canonical form; `SignInUseCase.call()` matches the repository signature.
- `reactive_state_syntax.md` rewritten; `reactive_state_patterns.md`, `di_patterns.md`, `di_conventions.md`, `widget_rules.md`, `imports.md`, `DECISIONS.md` updated.
- `Result` moved to `lib/core/domain/entities/result.dart` (matches `folder_naming`).
- `Result.success(value)` requires a non-nullable value; commands return the shared `static const Result<void> ok`.
- `Result.success` / `Result.failure` are `const factory`; the "cannot be const" note in `SKILL.md` was wrong and is replaced.
- Nullable `value` / `errorMessage` getters removed; `when(success:, failure:)` added. `isSuccess` / `isFailure` stay.
- Failure messages are human-readable constants; raw exceptions are logged. Repositories catch `on Exception` instead of a bare `catch (e)`.
- Template repository gets an injected `Logger` and logs success/failure.

### Added — Reference app, scripts, tests
- `assets/example_app/` — neutral notes app built with every rule (core, one feature on all layers, controller + `registerHandler`, tests on every layer); passes `flutter analyze`, `flutter test` and the linter with `--strict`.
- `scripts/selfcheck.py` — linter tests, versions, example app (analyze, test, lint), docs core == example core, auth template from the docs compiled inside the example app.
- `scripts/check_versions.py` — pinned versions (source: example pubspec) vs pub.dev; `--strict`, `--update` (bumps the pubspec and the docs).
- `tests/test_linter.py` — unit tests for the key linter rules and "the example app has no violations".
- `references/testing.md` — what to test on each layer, fakes, widget tests with the real DI, `Stream.multi` for data sources.
- Pinned versions: `get_it ^9.3.0`, `watch_it ^2.5.0`, `logger ^2.8.0`, `flutter_lints ^6.0.0`, `sdk ^3.12.0`.
- Linter `--version` (`__version__ = "0.5.0"`).

### Changed — Constants, scripts, git
- Values shared by several features live in `AppTheme` (`lib/core/presentation/theme.dart`); per-feature theme files are gone. Single-use values stay private `static const`.
- Linter `theme_import` rewritten: flags the same private constant in two features and spacing constants that duplicate `AppTheme`; it no longer flags every constant equal to 6/8/12/16/20/24 or looks for hard-coded `k…` names.
- `init_feature.py`: full skeleton incl. `controllers/` and `.gitkeep`, `use_cases/` (was `usecases/`), `--core` copies the verified core files from the example app and creates `lib/di.dart`.
- `git_rules.md` is project-agnostic (no project names, generic task numbers and checklist).
- `feature_template_auth.md`: Dartdoc on every public class, entities, in-memory `AuthDataSourceImpl`, `SignOutUseCase` — the template compiles as is.

### Fixed — Linter
- `value_listenable_exposure` missed public getters written as `ValueNotifier<T> get x => _x;`.
- Orphan rule `magic_strings_in_widgets` (declared, never implemented) removed.

### Changed (breaking) — DI
- One function per feature: `registerAndInit<Feature>()` replaces `register<Feature>()` + `init<Feature>()`; core: `registerAndInitCore()`.
- Startup work lives in the class: `Future<Impl> init()` returns `this`, registered with `registerSingletonAsync`; `registerAndInit()` awaits `di.allReady()`, so feature inits run in parallel. Cross-feature dependencies use `dependsOn`.
- Registration order bottom-up (data sources → repositories → use cases); `registerLazySingleton` wherever possible.
- `di` from watch_it replaces `GetIt.instance` / `GetIt.I` / local `getIt`; DI files and getters import only `package:watch_it/watch_it.dart`.
- Dependencies are injected with private named parameters (`{required this._logger}`, needs `sdk: ^3.12.0`).
- `init_feature.py` generates `registerAndInit<Feature>()` stubs.

### Added — Dispose
- `DisposableResource` (`lib/core/domain/entities/disposable_resource.dart`) — our own interface, no get_it in data/domain.
- `disposeResource()` in `core_di.dart` — passed as GetIt's `dispose:` callback; the only place DI meets our dispose contract.
- "Dispose — what and when" in `di_patterns.md`: what to release, session scope for logout, tests, app start, desktop exit.

### Added — Side effects
- `registerHandler(target: …, handler: _onX)` from watch_it for one-off reactions to state (navigation, snackbar, dialog); handler is a private method, `target:` keeps the listenable out of GetIt.
- Pattern "action result → controller → `registerHandler`" in `no_controllers.md`: controller calls the action use case and stores loading/error; the widget watches progress and shows errors. `_isDisposed` guard after `await`.
- The order rule for `watch()` / `registerHandler()` and linter rule `watch_order` (flags calls inside `if` / `for` / `switch` / callbacks).
- Template: `AuthStatusWidget` (watch) uses `SignInButtonWidget` (controller), new `AuthGateWidget` (registerHandler). The old `AuthStatusWidget` ignored the sign-in `Result`.
- `reactive_state_patterns.md`: side-effects table.

### Fixed — Linter
- `watching_widget` accepts `registerHandler(target: watch<Name>UseCase(), …)`.
- `static_const_order` flagged every `static const` in a `final class …State` (the `final` of the class declaration was taken for the first field).

### Fixed — Widgets
- `no_controllers.md` / `widget_rules.md` told to keep controllers in a `StatelessWidget`, which cannot dispose them; the owner is now a `StatefulWidget` / `WatchingStatefulWidget`.

### Fixed — DI
- `di_patterns.md` example used `AuthDataSource` before registering it (runtime crash), used an undeclared `getIt` in `initAuth()`, and called `init()` missing from the repository interface.

### Removed
- `references/initiations.md` (merged into `di_patterns.md`).
- State in GetIt via `instanceName` keys (a leftover from an early version that competed with the watch use case flow): `references/keys_naming.md`, `scripts/add_di_computed.py`, instanceName mentions in `SKILL.md`, `di_conventions.md`, `DECISIONS.md`, `init_feature.py` stubs.
- Linter rule `getit_key_naming` (replaced by `no_state_in_di`).

### Added
- Linter rule `no_state_in_di` — `instanceName` and `ValueNotifier` / `ValueListenable` registered in GetIt are violations.
- "Derived state" section in `reactive_state_syntax.md`.
- Linter rule `value_listenable_exposure` — `ValueNotifier` in domain, in public repository members or in getters is a violation.
- `watching_widget` flags `watchValue()` / `watchIt()` in presentation and requires `watch(watch<Name>UseCase())` in a `WatchingWidget`.

### Fixed
- `import_violation` now detects `use_cases/` imports (the regex only matched `usecases/` and `use_case/`).
- `di_patterns.md` linked to the non-existent `value_notifier_syntax.md`.
- `SKILL.md` listed 22 rules; the linter implements 27.

---

## [0.2.0] - 2025-01-01

### Added
- `DECISIONS.md` — visual decision table mapping "you need X → use pattern Y" across architecture, state, DI, data, UI, and conventions.
- Quick navigation section in `SKILL.md` pointing to `DECISIONS.md`.

---

## [0.1.0] - 2025-01-01

### Added
- Initial skill definition
- 22 linting rules in `scripts/dart_clean_arch_linter.py`
- Core references:
    - `di_patterns.md`
    - `di_conventions.md`
    - `feature_template_auth.md`
    - `folder_structure.md`
    - `models_mapping.md`
    - `widget_rules.md`
    - `no_controllers.md`
    - `imports.md`
    - `use_case_naming.md`
    - `reactive_state_patterns.md`
    - `reactive_state_syntax.md`
    - `result.md`
    - `dartdoc_standard.md`
    - `logging_conventions.md`
    - `keys_naming.md`
    - `initiations.md`
- Scripts:
    - `scripts/dart_clean_arch_linter.py`
    - `scripts/init_feature.py`
    - `scripts/add_di_computed.py`
- Default packages: `get_it`, `watch_it`, `logger`
- Workflows: create feature, refactor feature, migrate from Riverpod/Bloc/Streams
- Linter rules: `naming_file`, `naming_class`, `magic_numbers`, `magic_strings`, `magic_colors`, `widget_helpers`, `inline_callbacks`, `import_violation`, `setstate_usage`, `stateful_no_lifecycle`, `dartdoc_public`, `getit_key_naming`, `widget_stateless`, `watching_widget`, `no_controller_in_ui`, `static_const_order`, `no_build_return`, `async_gap_context_mounted`, `widget_key_parameter`, `controller_lifecycle`, `widget_methods`, `stateless_with_controllers`

---

## Versioning Policy

This skill follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** — Breaking changes to rules, architecture patterns, or required packages.
   Existing projects may fail linting after upgrade.
- **MINOR** — New rules, new references, new scripts, new templates.
   Existing projects should still pass. May require opting into new rules.
- **PATCH** — Bug fixes in scripts, typo corrections, clarifications in references.
   No behavior change for conforming projects.

---

## How to Use This Changelog

- When updating a Flutter project to a new skill version, review the diff between your
   current version and the target version.
- MAJOR upgrades may require refactoring; MINOR/PATCH should be safe.
- The linter version is tracked in `scripts/dart_clean_arch_linter.py` (see `__version__` constant).
