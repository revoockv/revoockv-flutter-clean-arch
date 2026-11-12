# revoockv-bloc — changelog

Versions of this template. The skill itself has its own versions (`CHANGELOG.md` in the skill root).

## [1.0.0] - 2026-11-12

- Made with the constructor from revoockv-original@1.0.0: the same layers, `Result`, models, style, tests and git
  rules; state in Bloc/Cubit (`rules/state/blocs.md`) instead of watch_it and `ValueNotifier`; dependencies as
  `RepositoryProvider`s in the widget tree (`rules/di/providers.md`) instead of GetIt; watch use cases return
  `Stream<Result<T>>`; blocs are the only use case callers.
- Example: the notes app rebuilt on flutter_bloc, tests with `bloc_test`.
- Lint: the watch_it rules are off; use cases may be imported in `blocs/` and `pages/` (`use_case_imports_in`).
- Example: the app of `docs/example_app.md` — notes (add, edit, delete) and statistics over one placeholder
  `AppDatabase` in core, with `NotesBloc`, `NoteActionsCubit`, `StatisticsBloc`, `HomeTabCubit`.
