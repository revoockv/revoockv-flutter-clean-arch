# Decision Table — "You need X → use pattern Y"

Use this table to quickly find the right reference file or pattern
without reading all references in full.

---

## Architecture & Layers

| You need to... | Read / use |
|---|---|
| Understand the overall folder structure | `rules/structure/folder_structure.md` |
| Create a new feature from scratch | `rules/examples/feature_template_auth.md` (golden template) |
| Refactor an existing feature | `rules/examples/feature_template_auth.md` + run linter |
| Migrate from Riverpod/Bloc/Streams | `rules/examples/feature_template_auth.md` + keep Streams in data sources |
| Define domain entities | Domain layer — sealed or simple classes, no tech details |
| Define a repository interface | Domain layer — interface only, no implementation |
| Define a use case | Domain layer — `rules/use_cases/use_case_naming.md` |

---

## State & Reactivity

| You need to... | Read / use |
|---|---|
| Understand ValueNotifier inside / ValueListenable outside | `rules/state/reactive_state_syntax.md` |
| Read state in a widget | `watch(watch<Name>UseCase()).value` — `rules/state/reactive_state_syntax.md` |
| Navigate / show a snackbar when state changes | `registerHandler(target: watch<Name>UseCase(), handler: _onX)` — `rules/state/reactive_state_syntax.md` |
| Show the progress / error of a user action | `<action>StateController` (`ValueNotifier<ResultState<void>>`) in a UI controller; the owner widget calls the use case and reacts with `registerHandler` — `rules/state/controllers.md` |
| Name a controller | `<noun>Controller` for the class, fields, locals and parameters (`savingStateController`); `<noun>FocusNode` — `rules/state/controllers.md` → "Naming" |
| Call a use case | `addSongUseCase(author: …)` in the owner widget's private method — never `.call`, never inside a controller — `rules/state/controllers.md` |
| Keep rebuilds few and low | `rules/state/controllers.md` → "Owner and rebuilds", `rules/state/reactive_state_patterns.md` |
| Fix "watch order" errors / conditional watch | The order rule — `rules/state/reactive_state_syntax.md` |
| Minimize rebuilds in a widget tree | `rules/state/reactive_state_patterns.md` |
| Decide when to use `WatchingWidget` vs `StatelessWidget` | `rules/state/widget_rules.md` |
| Know that `setState` is banned | `rules/state/controllers.md` |
| Decide whether a widget needs a controller (UI state only) | `rules/state/controllers.md` → "When a controller is needed" |

---

## Dependency Injection

| You need to... | Read / use |
|---|---|
| Register a feature's dependencies | `rules/di/di_patterns.md` |
| Expose derived state (e.g. `isSignedIn` from `AuthState`) | `rules/state/reactive_state_syntax.md` → "Derived state" |
| Know where DI files live | `rules/di/di_conventions.md` |
| Expose dependencies to widgets (getters) | `rules/di/di_conventions.md` (`<feature>_getters.dart`) |
| Call one-time startup work (subscriptions, SDK init) | `rules/di/di_patterns.md` (`init()` → `this` + `registerSingletonAsync`) |
| Wire up the main DI entry point | `rules/di/di_patterns.md` (`registerAndInit()`) |
| Release subscriptions / connections, decide when to dispose | `rules/di/di_patterns.md` → "Dispose" |

---

## Data Layer

| You need to... | Read / use |
|---|---|
| Create a DTO / data model | `rules/errors_models/models_mapping.md` |
| Map DTO ↔ Entity | `rules/errors_models/models_mapping.md` |
| Create ids of new records | Data source, UUID v4 (`uuid`) — `rules/errors_models/models_mapping.md` → "Ids" |
| Use Streams inside a data source | `rules/di/di_patterns.md` (Streams allowed in data_sources) |
| Convert Stream → ValueNotifier in repository (exposed as ValueListenable) | `rules/state/reactive_state_syntax.md` |
| Handle expected failures | `rules/errors_models/result.md` |
| Expose live data with loading / error | `ResultState<T>` — `rules/state/result_state.md` |

---

## Presentation / UI

| You need to... | Read / use |
|---|---|
| Choose StatelessWidget vs StatefulWidget | `rules/state/widget_rules.md` |
| Add a new widget to a feature | `rules/examples/feature_template_auth.md` |
| Name a use case | `rules/use_cases/use_case_naming.md` |
| Watch state correctly (`.value` after `watch()`) | `rules/state/reactive_state_syntax.md` |
| Know that deepest widgets must be dumb | `SKILL.md` → "Deepest widgets must be dumb" |
| Extract magic strings / numbers to `static const` | `SKILL.md` → "Constants — owning class, or core when shared" |
| Handle `Result<T>` in UI | `rules/errors_models/result.md` |
| Serve the app's use cases to other devices (HTTP / WebSocket) | an `api_server` feature — `rules/http/serving_http.md` |

---

## Conventions & Quality

| You need to... | Read / use |
|---|---|
| Write Dartdoc comments | `rules/style/dartdoc_standard.md` |
| Set up logging in a feature | `rules/style/logging_conventions.md` |
| Organize imports | `rules/style/imports.md` |
| Name files correctly | Linter rule `naming_file` |
| Name classes correctly | Linter rule `naming_class` |
| Avoid magic numbers/strings/colors | Linter rules `magic_numbers`, `magic_strings`, `magic_colors` |
| Put a constant used by several features | `AppTheme` in `lib/core/presentation/theme.dart` — `SKILL.md` → "Constants" |
| Write tests for a feature | `rules/testing/testing.md`, examples in `example/test/` |
| Pick package versions | `SKILL.md` → "Packages"; `scripts/check_versions.py` |
| Set up git branches / commit messages | `rules/git/git_rules.md` |
| Check the skill itself after editing it | `scripts/selfcheck.py` |
| Run the linter after changes | `SKILL.md` → "Automated linting" |
| Check if a rule can be ignored | `SKILL.md` → "Automated linting" (`--ignore` flag) |

---

## Workflows (Quick Reference)

### A) Create a new feature

```
1. scripts/init_feature.py    → create skeleton (--core once per project)
2. use_case_naming.md         → name use cases
3. models_mapping.md          → create DTOs + mapping
4. di_patterns.md             → registerAndInit<Feature>()
5. di_conventions.md          → add getters
6. widget_rules.md            → build UI
7. testing.md                 → tests on every layer
8. Run linter --strict        → verify
```

### B) Refactor an existing feature

```
1. feature_template_auth.md   → understand target shape
2. Refactor layer by layer
3. Run linter --strict        → verify all rules pass
```

### C) Migrate from Riverpod/Bloc/Streams

```
1. Keep Streams in data_sources
2. Repository: Stream → ValueNotifier
3. UI: replace Bloc/Riverpod listeners with watch(watch<Name>UseCase()).value and registerHandler
4. Remove bindings / cubits; UI-only logic that remains goes into controllers (controllers.md)
5. Run linter                 → verify
```

---

## When in Doubt

> Copy the pattern from `rules/examples/feature_template_auth.md` or `example/` and adapt naming only.
