# Decision Table — "You need X → use pattern Y"

Use this table to quickly find the right reference file or pattern
without reading all references in full.

---

## Architecture & Layers

| You need to... | Read / use |
|---|---|
| Understand the overall folder structure | `references/folder_structure.md` |
| Create a new feature from scratch | `references/feature_template_auth.md` (golden template) |
| Refactor an existing feature | `references/feature_template_auth.md` + run linter |
| Migrate from Riverpod/Bloc/Streams | `references/feature_template_auth.md` + keep Streams in data sources |
| Define domain entities | Domain layer — sealed or simple classes, no tech details |
| Define a repository interface | Domain layer — interface only, no implementation |
| Define a use case | Domain layer — `references/use_case_naming.md` |

---

## State & Reactivity

| You need to... | Read / use |
|---|---|
| Understand ValueNotifier inside / ValueListenable outside | `references/reactive_state_syntax.md` |
| Read state in a widget | `watch(watch<Name>UseCase()).value` — `references/reactive_state_syntax.md` |
| Navigate / show a snackbar when state changes | `registerHandler(target: watch<Name>UseCase(), handler: _onX)` — `references/reactive_state_syntax.md` |
| Show the progress / error of a user action | `ValueNotifier<ResultState<void>>` controller + `createOnce` + `registerHandler` — `references/controllers.md` |
| Keep rebuilds few and low | `references/controllers.md` → "Owner and rebuilds", `references/reactive_state_patterns.md` |
| Fix "watch order" errors / conditional watch | The order rule — `references/reactive_state_syntax.md` |
| Minimize rebuilds in a widget tree | `references/reactive_state_patterns.md` |
| Decide when to use `WatchingWidget` vs `StatelessWidget` | `references/widget_rules.md` |
| Know that `setState` is banned | `references/controllers.md` |
| Decide whether a widget needs a controller (UI logic only) | `references/controllers.md` → "When a controller is needed" |

---

## Dependency Injection

| You need to... | Read / use |
|---|---|
| Register a feature's dependencies | `references/di_patterns.md` |
| Expose derived state (e.g. `isSignedIn` from `AuthState`) | `references/reactive_state_syntax.md` → "Derived state" |
| Know where DI files live | `references/di_conventions.md` |
| Expose dependencies to widgets (getters) | `references/di_conventions.md` (`<feature>_getters.dart`) |
| Call one-time startup work (subscriptions, SDK init) | `references/di_patterns.md` (`init()` → `this` + `registerSingletonAsync`) |
| Wire up the main DI entry point | `references/di_patterns.md` (`registerAndInit()`) |
| Release subscriptions / connections, decide when to dispose | `references/di_patterns.md` → "Dispose" |

---

## Data Layer

| You need to... | Read / use |
|---|---|
| Create a DTO / data model | `references/models_mapping.md` |
| Map DTO ↔ Entity | `references/models_mapping.md` |
| Create ids of new records | Data source, UUID v4 (`uuid`) — `references/models_mapping.md` → "Ids" |
| Use Streams inside a data source | `references/di_patterns.md` (Streams allowed in data_sources) |
| Convert Stream → ValueNotifier in repository (exposed as ValueListenable) | `references/reactive_state_syntax.md` |
| Handle expected failures | `references/result.md` |
| Expose live data with loading / error | `ResultState<T>` — `references/result_state.md` |

---

## Presentation / UI

| You need to... | Read / use |
|---|---|
| Choose StatelessWidget vs StatefulWidget | `references/widget_rules.md` |
| Add a new widget to a feature | `references/feature_template_auth.md` |
| Name a use case | `references/use_case_naming.md` |
| Watch state correctly (`.value` after `watch()`) | `references/reactive_state_syntax.md` |
| Know that deepest widgets must be dumb | `SKILL.md` → "Deepest widgets must be dumb" |
| Extract magic strings / numbers to `static const` | `SKILL.md` → "Constants — owning class, or core when shared" |
| Handle `Result<T>` in UI | `references/result.md` |

---

## Conventions & Quality

| You need to... | Read / use |
|---|---|
| Write Dartdoc comments | `references/dartdoc_standard.md` |
| Set up logging in a feature | `references/logging_conventions.md` |
| Organize imports | `references/imports.md` |
| Name files correctly | Linter rule `naming_file` |
| Name classes correctly | Linter rule `naming_class` |
| Avoid magic numbers/strings/colors | Linter rules `magic_numbers`, `magic_strings`, `magic_colors` |
| Put a constant used by several features | `AppTheme` in `lib/core/presentation/theme.dart` — `SKILL.md` → "Constants" |
| Write tests for a feature | `references/testing.md`, examples in `assets/example_app/test/` |
| Pick package versions | `SKILL.md` → "Packages"; `scripts/check_versions.py` |
| Set up git branches / commit messages | `references/git_rules.md` |
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

> Copy the pattern from `references/feature_template_auth.md` or `assets/example_app/` and adapt naming only.
