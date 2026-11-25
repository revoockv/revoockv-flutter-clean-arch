# Testing

Every pattern below is in `example/test/` and runs green in `scripts/selfcheck.py`.

## Layout

```
test/features/<feature>/domain/<use_case>_test.dart
test/features/<feature>/data/<repository>_impl_test.dart
test/features/<feature>/presentation/<feature>_blocs_test.dart
test/features/<feature>/presentation/<page>_test.dart
test/features/<feature>/fake_<feature>_data_sources.dart — fake data sources shared by the tests
test/app_test_app.dart                                   — a page under the app's real providers, fakes optional
test/settle.dart                                         — lets streams deliver, then rebuilds
```

## What to test on each layer

| Layer | Test | Replace dependencies with |
|---|---|---|
| Domain: use cases | validation, what is passed to the repository, the `Result` | a fake repository (`implements <Feature>Repository`) |
| Data: repositories | the stream (first value, changes), stream error → `Result.failure`, write exceptions → human-readable failure | an in-memory or a failing data source; `Logger(level: Level.off)` |
| Presentation: blocs, cubits | the states for each event / method, failures, one action at a time | real use cases over a fake data source; `blocTest(build:, act:, expect:)` |
| Presentation: pages | the user flow: type, tap, see the list, the snackbar, a load error, a failed add keeps the text | `testApp(page, notes: FailingNotesDataSource())`: the app's providers with `createDataSource` / `createLogger` / `createDatabase` |

Fakes are plain classes that `implements` the interface — no mocking package. States are compared with `==`
(`expect: () => const <NotesState>[NotesLoaded(<Note>[])]`), so states that carry data define it.

Widget tests let streams deliver with `tester.runAsync(() => Future<void>.delayed(…))` and then `tester.pump()`
(`example/test/settle.dart`).

## Data sources: emit without losing events

A data source that exposes "current value + changes" must subscribe synchronously: `async*` + `yield*` subscribes only
after the first `yield` is consumed, so a change made in between is lost. Use `Stream.multi` —
`example/lib/core/data/data_sources/in_memory_app_database.dart`.
