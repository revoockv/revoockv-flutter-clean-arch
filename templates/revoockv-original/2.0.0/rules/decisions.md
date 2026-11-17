# Decisions — "you need X → do Y"

Quick answers; the file says the details. When in doubt, copy `rules/examples/auth_*.md` or `example/` and rename only.

## State and UI

| You need to… | Do | Details |
|---|---|---|
| Read state in a widget | `watch(watch<Name>UseCase()).value` in a `WatchingWidget` | `state/reactive_state_syntax.md` |
| React to a change (snackbar, navigation) | `registerHandler(target: …, handler: _onX)` — never in `build()` logic | `state/reactive_state_syntax.md` |
| Pick the screen for a state | `watch` + `switch` over the sealed state (`AuthGateWidget`) | `examples/auth_presentation.md` |
| Show progress / error of an action | `<action>StateController` (`ValueNotifier<ResultState<void, F>>`) in a UI controller; the owner widget calls the use case | `state/controllers.md` |
| Decide if a widget needs a controller | only for UI state (fields, focus, mode, progress) | `state/controllers.md` |
| Name a controller | `<noun>Controller` (class, fields, locals, parameters); `<noun>FocusNode` | `state/controllers.md` |
| Call a use case | `addSongUseCase(author: …)` in the owner widget's private method — never `.call`, never in a controller | `state/controllers.md` |
| Fix "watch order" errors | `watch` / `registerHandler` / `createOnce` unconditionally at the top of `build()` | `state/reactive_state_syntax.md` |
| Keep rebuilds few and low | watch in the lowest widget that shows the value | `state/rebuilds.md` |
| Use a part of a watched value (`isLoading`, `text`, a count) | `watchPropertyValue(_partOf, target: listenable)` — never `watch(x).value.part` | `state/rebuilds.md` |
| Show fast state (timer, level, playback position, typed text) | only the smallest widget that draws it watches it; the page selects a bool | `state/rebuilds.md` → "Fast state" |
| Data only one tab / area shows | the widget of that area watches it, not the page or shell | `state/rebuilds.md` → "Watch where it is shown" |
| `WatchingWidget` or `StatelessWidget` | Watching only when it calls `watch`/`registerHandler`/`createOnce` | `state/widget_rules.md` |
| `setState` | banned | `state/controllers.md` |
| Leaf widgets | pure: data + callbacks, no watch, no use cases; in their feature | `state/widget_placement.md` |
| A widget several features use | plain Flutter in `lib/core/presentation/widgets/` | `state/widget_placement.md` |
| Live data with loading / error | `ResultState<T, F>` | `state/result_state.md` |
| Derived state (`isSignedIn`) | a watch use case over the repository's notifier | `state/reactive_state_syntax.md` → "Derived state" |

## Domain, data, DI

| You need to… | Do | Details |
|---|---|---|
| Name a use case | `<Action>UseCase` (`SignInUseCase`); live state `Watch<Name>UseCase` | `use_cases/use_case_naming.md` |
| Expected failures | `Result<T, F>` with a failure enum of the feature, text in `presentation/l10n`; `on Exception catch` in the repository, no try/catch in use cases | `errors_models/result.md` |
| DTO ↔ entity | model in `data/models/` with `toEntity()` / `fromEntity()` | `errors_models/models_mapping.md` |
| Ids of new records | UUID v4 in the data source | `errors_models/models_mapping.md` |
| Streams | only in data sources; the repository turns them into its `ValueNotifier` | `state/reactive_state_syntax.md` |
| Register a feature | `registerAndInit<Feature>()`, bottom-up, lazy where possible | `di/di_patterns.md` |
| Startup work | `Future<Impl> init()` returning `this` + `registerSingletonAsync` | `di/di_patterns.md` |
| Release subscriptions | `DisposableResource` + `dispose: disposeResource` | `di/di_patterns.md` → "Dispose" |
| Use cases for widgets | top-level getters in `<feature>_getters.dart` | `di/di_conventions.md` |

## Conventions

| You need to… | Do | Details |
|---|---|---|
| A constant of one class | private `static const` of that class | `style/constants.md` |
| A value shared by features | `AppTheme` in `lib/core/presentation/theme.dart` | `style/constants.md` |
| Strings anywhere (UI, JSON keys, logs) | private `static const`; interpolation joins constants and values | `style/constants.md` |
| Inject dependencies | private named parameters `({required this._dataSource})` | `style/dart_style.md` |
| Dartdoc, logging, imports | every public declaration documented; logger injected | `style/*.md` |
| Tests | every layer; a test DI per feature with fake data sources | `testing/testing.md`, `example/test/` |
| Commits and branches | `[TYPE-NNN] …`, `--no-ff` merges, branches kept | `git/git_rules.md` |

## Migrating from Riverpod / Bloc / streams

1. Keep the library's streams in data sources.
2. Repository: stream → private `ValueNotifier`, exposed as `ValueListenable`.
3. UI: listeners → `watch(watch<Name>UseCase()).value` and `registerHandler`.
4. Remove providers / cubits; UI-only logic that remains goes into controllers.
5. Run the linter.
