# example_app

The example app of `docs/example_app.md` (notes + statistics over a placeholder database), built with the
`revoockv-original` template: GetIt + watch_it, `ValueNotifier` inside, `ValueListenable` outside.

| Where | What it shows |
|---|---|
| `lib/core/data/` | `AppDatabase` + `InMemoryAppDatabase`: tables of rows, change streams (`Stream.multi`), latency, missing rows throw |
| `lib/core/presentation/` | `registerAndInitCore()` (logger, database), `HomePage` with the tabs and its `HomeController` |
| `lib/features/notes/` | entity, model ↔ row ↔ entity, data source over the database (UUID ids, clock), repository with a private `ValueNotifier`, add / edit / delete use cases, `NotesController` owned with `createOnce`, `registerHandler` on the page, edit dialog |
| `lib/features/statistics/` | its own data source and model over the same `notes` table, `NotesStatistics.of` in the domain, a watch use case, a page that watches it |
| `test/` | database, use cases with a fake repository, repositories, the controller, page flows and tab switching with `test/app_test_di.dart` |

```bash
flutter pub get && flutter analyze && flutter test
python3 ../../../../scripts/dart_clean_arch_linter.py lib --strict
```
