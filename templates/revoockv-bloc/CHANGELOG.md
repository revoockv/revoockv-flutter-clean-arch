# revoockv-bloc — changelog

Versions of this template. The skill itself has its own versions (`CHANGELOG.md` in the skill root).

## [1.1.0]

- Made from revoockv-bloc@1.0.0.

## [1.1.0]

- Made from revoockv-bloc@1.0.0.
- Objects, not maps (`rules/errors_models/objects_not_maps.md`, `decisions.md`, `[choices] models`): data with a shape
  is a class; `Map<String, dynamic>` only at the storage boundary (models in `data/models/`, data sources); no `Map` in
  the public API of entities, use cases, repository interfaces, widgets and blocs (an object that answers by id
  or a `List` of entities); local lookups and private caches stay maps.
- Lint: `objects_not_maps` is on (`[lint] on`).
- Git (`rules/git/git_rules.md`): "Choose the type" — questions in order (the user's word, hotfix, fix, feature,
  refactor, docs, test/style) and wrong → right examples, decided before the branch is created; a merge into
  `develop` only after the user confirms the task is solved; corrections of a task stay on its branch.

## [1.0.0] - 2026-11-12

- Made with the constructor from revoockv-original@1.0.0: the same layers, `Result`, models, style, tests and git
  rules; state in Bloc/Cubit (`rules/state/blocs.md`) instead of watch_it and `ValueNotifier`; dependencies as
  `RepositoryProvider`s in the widget tree (`rules/di/providers.md`) instead of GetIt; watch use cases return
  `Stream<Result<T>>`; blocs are the only use case callers.
- Example: the notes app rebuilt on flutter_bloc, tests with `bloc_test`.
- Lint: the watch_it rules are off; use cases may be imported in `blocs/` and `pages/` (`use_case_imports_in`).
- Example: the app of `docs/example_app.md` — notes (add, edit, delete) and statistics over one placeholder
  `AppDatabase` in core, with `NotesBloc`, `NoteActionsCubit`, `StatisticsBloc`, `HomeTabCubit`.
