# Workflow — layers and operations

This template is strict. When a decision is unclear, copy the patterns of `rules/examples/feature_template_auth.md` or of `example/` (a notes app built with every rule: core, one feature on all layers, DI, a UI controller owned with `createOnce`, a page that calls the use cases and reacts with `registerHandler`, tests on every layer) and adapt the names only. Run the linter after every change.

## Layer responsibilities

- Domain: entities (sealed or simple), repo interfaces, use cases (no tech details).
- Data: data_sources/services (Streams allowed), models/DTO mapping, repository implementations that own a private `ValueNotifier<T>` and expose it outward only as `ValueListenable<T>`.
- Presentation: pages/widgets + DI + getters + optional controllers. A controller holds UI state only, like Flutter's `TextEditingController`: it never calls use cases and never touches the data layer. The owner widget calls the use cases; domain/data state comes from `watch…UseCase` getters (`rules/state/controllers.md`).

## Workflow: choose the operation

### A) Create a new feature

1. Create folder skeleton under `lib/features/<feature>/...` (see `rules/structure/folder_structure.md`).
2. Implement Domain first:
   - entities
   - repository interface
   - use cases
3. Implement Data:
   - data_sources/services (Streams allowed)
   - models (DTO) in `data/models/` with Model↔Entity mapping
   - repository implementation: private `ValueNotifier<T>` field, public `ValueListenable<T> watch<Name>()` returning that same field
   - startup work in `Future<Impl> init()` that returns `this`; classes owning subscriptions/controllers/connections implement `DisposableResource`
4. Presentation DI (`rules/di/di_patterns.md`):
   - one function `registerAndInit<Feature>()` in `<feature>_di.dart`, using `di` from watch_it
   - register bottom-up: data sources → repositories → use cases; `registerLazySingleton` wherever possible, `registerSingletonAsync(() => Impl(...).init())` for startup work; `dispose: disposeResource` for every `DisposableResource`
   - `lib/di.dart` → `registerAndInit()` calls every `registerAndInit<Feature>()` and awaits `di.allReady()`
   - expose every use case as a top-level getter in `<feature>_getters.dart` that returns the use case object (e.g., `WatchSongsUseCase get watchSongsUseCase => di<WatchSongsUseCase>();`)
   - the getter name without parentheses is the use case; with parentheses (`addSongUseCase()`) it invokes `call()`
5. UI:
    - small widgets, tight watch scopes
    - **Reading state:** domain/data state — `final ResultState<List<Song>> songs = watch(watchSongsUseCase()).value;`; UI state of a controller — `final bool isLoading = watch(songFormController.savingStateController).value.isLoading;`. `watch()` subscribes and returns the `ValueListenable` itself, so `.value` follows it.
    - `watchValue()` and `watchIt()` are not used in widgets (linter: `watching_widget`).
    - **Reacting to state** (navigation, snackbar, dialog) uses `registerHandler(target: watch<Name>UseCase(), handler: _onX)` (or `target: songFormController.savingStateController` — a notifier of a UI controller) — the handler is a private method `(BuildContext context, T value, void Function() cancel)` and runs only on a change (`executeImmediately: true` for the first value too). Never put these into `build()`. Which screen a state needs (signed out → sign-in) is not a reaction: `watch` + `switch` over the sealed state picks the widget (`AuthGateWidget`).
    - **The order rule:** `watch()` / `registerHandler()` / `createOnce()` are called unconditionally at the top of `build()` — never inside `if` / `for` / `switch` or callbacks (linter: `watch_order`).
    - **`WatchingWidget` rule:** Only extend `WatchingWidget` (or `WatchingStatefulWidget`) when the widget calls `watch()` / `registerHandler()` — on a watch use case (`watch(watchSongsUseCase())`) or on a notifier of its controller (`watch(songFormController.savingStateController)`), or owns a controller with `createOnce()`. Watch use cases start with `watch` and return `ValueListenable<T>` (e.g., `watchSongsUseCase`, `watchCurrentSessionUseCase`).
    - **Mandatory:** `watch()` / `registerHandler()` / `createOnce()` only work inside `WatchingWidget` / `WatchingStatefulWidget`; in `StatelessWidget` / `StatefulWidget` they throw a runtime assertion error.
    - **Action use cases** (e.g., `addSongUseCase`, `deleteSongUseCase`, `updateSongUseCase`) return `Future<Result>`. When the UI shows nothing around the action, a private method of the widget calls the use case directly (`void _onSignOutPressed() { signOutUseCase(); }`) — no controller. When the UI shows progress, the error or form state, that state goes into a controller — like Flutter's `TextEditingController`, it holds UI state only (`ValueNotifier<ResultState<void>> savingStateController`, `rules/state/result_state.md`) and never takes or calls use cases. The owner is a `WatchingWidget` that creates it with `createOnce(_createSongFormController, dispose: _disposeSongFormController)`, **calls the use case itself** in a private method (`addSongUseCase(author: …)` — never `addSongUseCase.call`): skip while loading, set `loading`, `await`, `if (songFormController.isDisposed) return;`, set `ResultState.of(result)`. It reacts to failures with `registerHandler(target: songFormController.savingStateController, handler: _onSavingChanged)` — no rebuild; only the lowest widget that shows progress calls `watch(savingState).value.isLoading` — `rules/state/controllers.md`.
    - **Controller naming:** every controller — the class, fields, locals and parameters — ends with `Controller` and is a noun of what it holds: `songFormController`, `authorController`, `savingStateController`, `signUpModeController` (not `saveState`, `isSignUp`); a `FocusNode` ends with `FocusNode` (linter: `controller_naming`).
    - **One state — one notifier:** the state of one thing is one value (a sealed class, an enum, `ResultState`), not several notifiers; split only parts that change independently.
    - If a widget extends `WatchingWidget` without one of these calls, or calls them outside a Watching widget, the linter flags a `watching_widget` violation.
    - `ValueNotifier` never leaks outward: domain, public repository members and getters use `ValueListenable<T>` (linter: `value_listenable_exposure`). See `rules/state/reactive_state_syntax.md`.

     - **Deepest widgets must be dumb:** The deepest (most nested) widgets in the widget tree — buttons, list items, tiles, dialog actions — must know nothing about use cases, repositories, or business logic. They receive data as constructor parameters and expose callbacks (`onPressed`, `onTap`, `onChanged`). All use case calls belong in the closest parent widget that owns the screen: the `WatchingWidget` that owns the controller (`createOnce`), or — when there is no UI state — the parent widget that calls the use case in a private method. A leaf widget gets at most a `ValueListenable<T>` to show (`savingState`), never a feature controller, so it can be reused anywhere. The deepest widgets should be as simple as possible: they render UI and forward events.

Golden reference:
- `rules/examples/feature_template_auth.md`

### B) Refactor an existing feature

Use:
- `rules/examples/feature_template_auth.md`
- Run `scripts/dart_clean_arch_linter.py` after refactoring to verify all rules pass.

### C) Migrate from Riverpod/Bloc/Streams

- Keep Streams inside data sources where the library uses Streams.
- Repositories hold a private `ValueNotifier<T>` and expose `ValueListenable<T>` outward.
- UI uses `watch(watch<Name>UseCase()).value` inside `WatchingWidget` from watch_it.

Use:
- `rules/examples/feature_template_auth.md`
