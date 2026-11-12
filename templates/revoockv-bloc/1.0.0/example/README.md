# example_app

Neutral notes app — the runnable reference of the `revoockv-bloc` template.

| Where | What it shows |
|---|---|
| `lib/di.dart`, `lib/main.dart` | `AppProvidersWidget` above `MaterialApp`: core, then the notes providers |
| `lib/core/` | `Result`, `CoreProvidersWidget` (logger), shared `AppTheme` |
| `lib/features/notes/domain/` | entity with `==`, repository interface, `WatchNotesUseCase` (`Stream<Result<…>>`) and action use cases |
| `lib/features/notes/data/` | model ↔ entity, in-memory data source (`Stream.multi`, UUID ids, `dispose()`), repository: stream errors and exceptions → `Result.failure` |
| `lib/features/notes/presentation/` | `NotesProvidersWidget`, `NotesBloc` (`emit.forEach`), `NoteActionsCubit` (one action at a time), page with `BlocProvider` + `BlocListener`, `context.select` only in the button, dumb tiles |
| `test/` | use case with a fake repository, repository streams, blocs with `bloc_test`, page flows under the real providers with fake data sources |

```bash
flutter pub get
flutter analyze
flutter test
python3 ../../../../scripts/dart_clean_arch_linter.py lib --strict --template revoockv-bloc
```

`scripts/selfcheck.py --template revoockv-bloc@1.0.0` runs all of this on a temp copy.
