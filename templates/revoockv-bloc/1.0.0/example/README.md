# example_app

The example app of `docs/example_app.md` (notes + statistics over a placeholder database), built with the
`revoockv-bloc` template: flutter_bloc, dependencies in the widget tree.

| Where | What it shows |
|---|---|
| `lib/core/data/` | `AppDatabase` + `InMemoryAppDatabase`: tables of rows, change streams (`Stream.multi`), latency, missing rows throw |
| `lib/core/presentation/` | `CoreProvidersWidget` (logger, database), `HomePage` with the tabs and its `HomeTabCubit` |
| `lib/di.dart`, `lib/main.dart` | `AppProvidersWidget` above `MaterialApp`: core, then the notes and statistics providers |
| `lib/features/notes/` | entity with `==`, model ↔ row ↔ entity, data source over the database, repository returning `Stream<Result<…>>`, `NotesBloc` (`emit.forEach`), `NoteActionsCubit` (add / edit / delete, one at a time), page with `BlocProvider` + `BlocListener`, edit dialog |
| `lib/features/statistics/` | its own data source and model over the same `notes` table, `NotesStatistics.of` in the domain, `StatisticsBloc` |
| `test/` | database, use cases, repositories, blocs with `bloc_test`, page flows and tab switching under the real providers (`test/app_test_app.dart`) |

```bash
flutter pub get && flutter analyze && flutter test
python3 ../../../../scripts/dart_clean_arch_linter.py lib --strict --template revoockv-bloc
```
