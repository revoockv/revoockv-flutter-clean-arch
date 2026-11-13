# Workflow — layers and operations

This template is strict. When a decision is unclear, copy the patterns of `rules/examples/auth_*.md` or of `example/` (a notes app built with every rule: core, one feature on all layers, DI, a UI controller owned with `createOnce`, a page that calls the use cases and reacts with `registerHandler`, tests on every layer) and adapt the names only. Run the linter after every change.

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
4. DI (`rules/di/di_patterns.md`): `registerAndInit<Feature>()` in `<feature>_di.dart`, bottom-up (data sources →
   repositories → use cases), called from `registerAndInit()` in `lib/di.dart`; every use case gets a top-level getter
   in `<feature>_getters.dart` (`addSongUseCase()` calls it).
5. UI (`rules/state/`): read state with `watch(watch<Name>UseCase()).value`, react with `registerHandler`
   (`reactive_state_syntax.md`); UI state in a controller that the owner `WatchingWidget` creates with `createOnce`
   and that never calls use cases — the owner calls them (`controllers.md`); widget shape (`widget_rules.md`).
6. Tests on every layer (`rules/testing/testing.md`), then the linter.

Worked feature: `rules/examples/auth_*.md`.

### B) Refactor an existing feature

Bring it to the shape of `rules/examples/auth_*.md` layer by layer, then run the linter.

### C) Migrate from Riverpod/Bloc/Streams

See `rules/decisions.md` → "Migrating".
