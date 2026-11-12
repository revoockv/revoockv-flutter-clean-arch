# Testing

Every pattern below is used in `example/test/` and runs green in `scripts/selfcheck.py`.

## Layout

Tests mirror `lib/`:

```
test/features/<feature>/domain/<use_case>_test.dart
test/features/<feature>/data/<repository>_impl_test.dart
test/features/<feature>/presentation/<page>_test.dart
test/features/<feature>/presentation/<controller>_test.dart
test/features/<feature>/fake_<feature>_data_sources.dart — fake data sources shared by the tests
test/app_test_di.dart                                    — test DI of the app (every feature, fakes optional)
test/settle.dart                                         — lets streams deliver, then rebuilds
```

## What to test on each layer

| Layer | Test | Replace dependencies with |
|---|---|---|
| Domain: use cases | validation, what is passed to the repository, the `Result` | a fake repository (`implements <Feature>Repository`) |
| Data: repositories | stream → `ValueListenable`, `Result.ok` / human-readable `Result.failure`, `init()` / `dispose()` | an in-memory or a failing data source; `Logger(level: Level.off)` |
| Presentation: controllers | the UI state: initial values, mode switches, validation, `isDisposed` | nothing — a controller has no dependencies |
| Presentation: pages | the user flow: tap, type, see the result, see the snackbar, see a load error, a failed save keeps the input | the **test DI** of the app with a fake data source — `registerAndInitForTest(notes: FailingNotesDataSource())` |

Fakes are plain classes that `implements` the interface — no mocking package is required.

## Domain: fake repository

```dart
final class FakeNotesRepository implements NotesRepository {
  final List<String> added = <String>[];

  @override
  Future<Result<void>> addNote(String text) async {
    added.add(text);
    return Result.ok;
  }
  // other members …
}

test('blank text fails without calling the repository', () async {
  final FakeNotesRepository repository = FakeNotesRepository();

  final Result<void> result = await AddNoteUseCase(repository)('   ');

  expect(result.isFailure, isTrue);
  expect(repository.added, isEmpty);
});
```

## Data: repository with a real or failing data source

```dart
test('exceptions become a human-readable failure', () async {
  final NotesRepositoryImpl repository =
      await NotesRepositoryImpl(dataSource: FailingNotesDataSource(), logger: Logger(level: Level.off)).init();

  final Result<void> result = await repository.addNote('First');

  result.when(
    success: (_) => fail('expected a failure'),
    failure: (String error) => expect(error, 'Could not add the note'),
  );
  await repository.dispose();
});
```

- Call `init()` exactly like DI does, and `dispose()` at the end.
- After a write, `await Future<void>.delayed(Duration.zero)` lets the stream deliver the change before reading `watch<Name>().value`.

## Presentation: controller

A controller holds UI state only and has no dependencies, so its test just creates it — no DI, no fakes. The use case
calls (progress, errors, a failed add keeping its text) are tested through the page with a test DI (below):

```dart
test('starts with an empty note and idle actions', () {
  final NotesController notesController = NotesController();

  expect(notesController.noteTextController.text, isEmpty);
  expect(notesController.addingStateController.value.isIdle, isTrue);
  notesController.dispose();
});
```

## Presentation: widget test with a test DI

The app's `registerAndInit()` uses the real data sources (Firebase, API, database), so widget tests never call it.
`test/app_test_di.dart` has `registerAndInitForTest({NotesDataSource? notes, StatisticsDataSource? statistics})`: the
same registrations as `lib/di.dart` and the features' DI, with a silent logger, a database without latency and the
given fakes — `example/test/app_test_di.dart`. A widget test registers what its scenario needs, right before the
widget — `example/test/features/notes/presentation/notes_page_test.dart`:

```dart
tearDown(() async => di.reset());          // disposes every DisposableResource

testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
  await registerAndInitForTest(notes: FailingNotesDataSource());
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NotesPage())));
  await settle(tester);
  …
  await tester.pumpWidget(const SizedBox());   // leave the screen before di.reset()
});
```

Rules:
- **Only data sources are replaced.** Repositories, use cases and getters are the real ones — the test goes through the real logic without the network.
- **The test DI is a copy of the app's DI with other data sources.** When a feature DI changes (a new use case, a new repository), change the test DI too.
- **Each test registers its own DI** before the widget (`registerAndInitForTest(...)` starts with `di.reset()`), `tearDown` → `di.reset()`: every test starts clean, no leaked subscriptions.
- Fake data sources are plain classes that `implements` the interface, in one shared file (`fake_<feature>_data_sources.dart`) — the repository tests use them too.
- Real streams and timers run outside the fake test clock: wrap waits in `tester.runAsync`, then pump (`example/test/settle.dart`).
- Remove the widgets (`pumpWidget(const SizedBox())`) before `di.reset()` — a widget still watching a disposed `ValueNotifier` throws.

## Data sources: emit without losing events

A data source that exposes "current value + changes" must subscribe synchronously. `async*` + `yield*` subscribes
only after the first `yield` is consumed, so a change made in between is lost. Use `Stream.multi` —
`example/lib/core/data/data_sources/in_memory_app_database.dart`.
