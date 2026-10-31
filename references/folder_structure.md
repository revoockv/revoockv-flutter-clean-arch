# Folder structure

`core/` mirrors the full feature layout: it must contain the same layer folders (`data/`, `domain/`, `presentation/`) with the same subfolders as a feature.

## Root

- `lib/di.dart` — main DI file: defines `registerAndInit()` (called by `main.dart`), which calls every `registerAndInit<Feature>()`
- `lib/core/`
    - `data/`
        - `data_sources/`
        - `models/`
        - `repositories/`
    - `domain/`
        - `entities/` — domain entities (sealed or simple). All domain files belong here (e.g. `result.dart`, `result_state.dart` and `disposable_resource.dart` live in `domain/entities/`, NEVER directly in `domain/`).
        - `repositories/`
        - `use_cases/`
    - `presentation/`
        - `pages/`
        - `widgets/`
        - `di/` — `core_di.dart`: `registerAndInitCore()`, `disposeResource()`
        - `controllers/`
        - `theme.dart` — `AppTheme`: values shared by several features (spacing, sizes, colors)
- `lib/features/`
- `lib/main.dart`

The `folder_naming` linter rule enforces this for both features and `core/`: **every** subfolder listed here must exist, even when empty, and no other subfolders are allowed. Empty folders contain a `.gitkeep` so git keeps them (`scripts/init_feature.py` creates them). The rule also flags any `.dart` file sitting directly inside a `domain/` directory (a file must be under `domain/entities/`, `domain/repositories/`, or `domain/use_cases/`).

## Feature

- `lib/features/<feature>/`
  - `data/` — data layer (technology-specific implementations)
    - `data_sources/` — abstract interfaces and implementations for external data (APIs, databases, SDKs)
    - `models/` — DTOs (data transfer objects) that map to/from domain entities
    - `repositories/` — repository implementations: private `ValueNotifier<T>`, public `ValueListenable<T>`
  - `domain/` — domain layer (business logic, independent of technology)
    - `entities/` — business entities (sealed or simple classes)
    - `repositories/` — repository interfaces (abstract contracts)
    - `use_cases/` — use case classes (`<Action>UseCase`, `Watch<Name>UseCase`)
  - `presentation/` — presentation layer (UI + DI wiring)
    - `pages/` — top-level page widgets (`*_page.dart`)
    - `widgets/` — reusable widget components (`*_widget.dart`)
    - `di/` — DI registration and getters
      - `<feature>_di.dart` — feature DI (`registerAndInit<Feature>()`)
      - `<feature>_getters.dart` — top-level getters for use cases
      - `<subfeature>_di.dart` — optional subfeature DI
    - `controllers/` — UI controllers, only when the feature has UI logic (loading flags, errors of actions, form state); otherwise empty with `.gitkeep`
    - optional, only in a feature that serves HTTP (`references/serving_http.md`) — not required, created only when used:
      - `routes/` — `RouterInjectable` classes with the handlers (`*_routes.dart`)
      - `dto/` — API formats of requests and responses (`*_dto.dart`)
      - `middleware/` — Relic middleware, e.g. the token check (`*_middleware.dart`)

## Naming

- Main DI: `lib/di.dart` — exposes `registerAndInit()`
- Feature DI: `lib/features/<feature>/presentation/di/<feature>_di.dart` — exposes `registerAndInit<Feature>()`: registers the feature and starts its async `init()`s (see `references/di_patterns.md`).
- Feature getters: `lib/features/<feature>/presentation/di/<feature>_getters.dart`
- Subfeature DI: `lib/features/<feature>/presentation/di/<subfeature>_di.dart`
