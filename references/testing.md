# Testing

Every pattern below is used in `assets/example_app/test/` and runs green in `scripts/selfcheck.py`.

## Layout

Tests mirror `lib/`:

```
test/features/<feature>/domain/<use_case>_test.dart
test/features/<feature>/data/<repository>_impl_test.dart
test/features/<feature>/presentation/<page>_test.dart
test/features/<feature>/presentation/<controller>_test.dart
test/features/<feature>/<feature>_test_di.dart          — test DI of the feature
test/features/<feature>/fake_<feature>_data_sources.dart — fake data sources shared by the tests
```

## What to test on each layer

| Layer | Test | Replace dependencies with |
|---|---|---|
| Domain: use cases | validation, what is passed to the repository, the `Result` | a fake repository (`implements <Feature>Repository`) |
| Data: repositories | stream → `ValueListenable`, `Result.ok` / human-readable `Result.failure`, `init()` / `dispose()` | an in-memory or a failing data source; `Logger(level: Level.off)` |
| Presentation: controllers | progress, the recorded error, a second start while busy | plain functions passed instead of use cases — no DI |
| Presentation: pages | the user flow: tap, type, see the result, see the snackbar, see a load error | a **test DI** of the feature with a fake data source — `registerAndInit<Feature>ForTest(FakeDataSource())` |

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

## Presentation: controller with plain functions

A controller gets its use cases through the constructor as functions, so its test passes plain functions — no DI, no fakes:

```dart
test('a failure becomes FailureResultState<void> with the message', () async {
  final NotesController controller = NotesController(
    add: (String text) async => const Result.failure('Could not add'),
    delete: (String id) async => Result.ok,
  );

  await controller.addNote('x');

  expect(controller.value, isA<FailureResultState<void>>());
  expect((controller.value as FailureResultState<void>).message, 'Could not add');
  controller.dispose();
});
```

## Presentation: widget test with a test DI

The app's `registerAndInit()` uses the real data sources (Firebase, API, database), so widget tests never call it. Each feature has its own **test DI** in `test/`: the same registrations as `registerAndInit<Feature>()`, but the data source is the one the test passes in. The app code stays untouched.

`test/features/notes/notes_test_di.dart`

```dart
/// Test DI of the notes feature: the same registrations as `registerAndInitNotes()`,
/// with [dataSource] instead of the real storage.
///
/// Keep it in sync with `lib/features/notes/presentation/di/notes_di.dart`.
Future<void> registerAndInitNotesForTest(NotesDataSource dataSource) async {
  await di.reset();

  // core — a silent logger
  di.registerSingleton<Logger>(Logger(level: Level.off));

  // 1. data sources — the one the test chose
  di.registerSingleton<NotesDataSource>(dataSource, dispose: disposeResource);

  // 2. repositories
  di.registerSingletonAsync<NotesRepository>(
    () => NotesRepositoryImpl(dataSource: di<NotesDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchNotesUseCase>(() => WatchNotesUseCase(di<NotesRepository>()));
  di.registerLazySingleton<AddNoteUseCase>(() => AddNoteUseCase(di<NotesRepository>()));
  di.registerLazySingleton<DeleteNoteUseCase>(() => DeleteNoteUseCase(di<NotesRepository>()));

  await di.allReady();
}
```

Every test registers what its scenario needs, right before the widget:

```dart
/// Lets streams deliver their events, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  await tester.pump();
}

void main() {
  tearDown(() async => di.reset());          // disposes every DisposableResource

  testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
    await registerAndInitNotesForTest(FailingNotesDataSource());
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Could not add the note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());   // leave the screen before di.reset()
  });

  testWidgets('a load error is shown instead of the list', (WidgetTester tester) async {
    await registerAndInitNotesForTest(BrokenStreamNotesDataSource());
    …
  });
}
```

Rules:
- **Only data sources are replaced.** Repositories, use cases and getters are the real ones — the test goes through the real logic without the network.
- **A test DI is a copy of `registerAndInit<Feature>()` with another data source.** When the feature DI changes (a new use case, a new repository), change its test DI too.
- **Each test registers its own DI** before the widget (`registerAndInit<Feature>ForTest(...)` starts with `di.reset()`), `tearDown` → `di.reset()`: every test starts clean, no leaked subscriptions.
- Fake data sources are plain classes that `implements` the interface, in one shared file (`fake_<feature>_data_sources.dart`) — the repository tests use them too.
- Real streams and timers run outside the fake test clock: wrap waits in `tester.runAsync`, then `pump()`.
- Remove the widgets (`pumpWidget(const SizedBox())`) before `di.reset()` — a widget still watching a disposed `ValueNotifier` throws.

## Data sources: emit without losing events

A data source that exposes "current value + changes" must subscribe synchronously. `async*` + `yield*` subscribes only after the first `yield` is consumed, so a change made in between is lost (the example's repository test caught exactly this). Use `Stream.multi`:

```dart
@override
Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.multi(_onListen);

void _onListen(MultiStreamController<List<NoteModel>> listener) {
  listener.add(List<NoteModel>.unmodifiable(_notes));
  final StreamSubscription<List<NoteModel>> sub = _changes.stream.listen(
    listener.add,
    onError: listener.addError,
    onDone: listener.close,
  );
  listener.onCancel = sub.cancel;
}
```
