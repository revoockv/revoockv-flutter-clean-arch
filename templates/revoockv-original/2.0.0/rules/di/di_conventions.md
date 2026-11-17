# DI conventions (GetIt)

- Feature DI: `presentation/di/<feature>_di.dart`
- Feature getters: `presentation/di/<feature>_getters.dart`
- Optional subfeature DI: `presentation/di/<subfeature>_di.dart`
- Register everything by type. `instanceName` keys are not used, and GetIt never holds a `ValueNotifier` / `ValueListenable` — state lives in repositories (linter: `no_state_in_di`).
- Widgets never call GetIt directly; they import getters.
- Getters expose use case objects as top-level getters (e.g., `addSongUseCase`, `watchSongsUseCase`) that widgets import. Getters never return `ValueNotifier`.
- Only `presentation/di/` imports repositories, use cases and data sources: `<feature>_di.dart` constructs them, `<feature>_getters.dart` exposes the use cases. Pages, widgets and controllers never import them — they reach use cases through `<feature>_getters.dart` (linter: `import_violation`).
