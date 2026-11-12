# Workflow — layers and operations

This template is strict. When a decision is unclear, copy the patterns of `example/` (a notes app built with every
rule: core, one feature on all layers, providers in the tree, a Bloc for the list, a Cubit for actions, tests on every
layer) and adapt the names only. Run the linter after every change.

## Layer responsibilities

- Domain: entities, repository interfaces, use cases (`Future<Result<T>>`, `Stream<Result<T>>`); no Flutter, no bloc.
- Data: data sources (streams allowed), models with mapping, repositories: models → entities, exceptions → failures.
- Presentation: `<Feature>ProvidersWidget` (dependencies), blocs/cubits (state, the only use case callers), pages
  (create the blocs), widgets (show state, send actions).

## A) Create a new feature

1. `python3 <skill_base>/scripts/init_feature.py --feature <name>` — folders and the providers stub
   (`rules/structure/folder_structure.md`).
2. Domain: entities, repository interface, use cases (`rules/use_cases/use_case_naming.md`).
3. Data: data source (+ `dispose()` when it owns resources), models (`rules/errors_models/models_mapping.md`), repository
   (`rules/errors_models/result.md`).
4. DI: fill `<Feature>ProvidersWidget` bottom-up and add it to `AppProvidersWidget` in `lib/di.dart`
   (`rules/di/providers.md`).
5. Presentation: a Bloc for live data, a Cubit for actions; the page creates them with `BlocProvider`; widgets watch,
   select and listen (`rules/state/blocs.md`, `rules/state/widget_rules.md`).
6. Tests on every layer (`rules/testing/testing.md`), then the linter.

## B) Refactor an existing feature

Bring it to the shape of `example/lib/features/notes/` layer by layer, then run the linter.

## C) Migrate from GetIt / watch_it / Provider / Riverpod

See `rules/decisions.md` → "Migrating".
