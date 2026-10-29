# example_app

Neutral notes app — the runnable reference of the `revoockv-flutter-clean-arch` skill.

| Where | What it shows |
|---|---|
| `lib/core/` | `Result`, `DisposableResource`, `ResultState`, `registerAndInitCore()` / `disposeResource()`, shared `AppTheme` |
| `lib/features/notes/domain/` | entity, repository interface, watch + action use cases (validation in the use case) |
| `lib/features/notes/data/` | model ↔ entity, in-memory data source (`Stream.multi`, UUID ids), repository: private `ValueNotifier`, `init()` / `dispose()`, `Result` |
| `lib/features/notes/presentation/` | `registerAndInitNotes()`, getters, `ValueNotifier<ResultState<void>>` controller (use cases through the constructor) owned with `createOnce`, `registerHandler` on the page, `watch` only in the button, `watch(watchNotesUseCase()).value`, dumb tiles |
| `test/` | use case with a fake repository, repository with real/failing data sources, controller with plain functions, widget flows with a test DI and fake data sources (`test/features/notes/notes_test_di.dart`) |

```bash
flutter pub get
flutter analyze
flutter test
python3 ../../scripts/dart_clean_arch_linter.py lib --strict
```

`scripts/selfcheck.py` runs all of this on a temp copy.
