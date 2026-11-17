import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../fake_notes_data_sources.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

/// The loaded notes of [repository]; fails the test when they are not loaded.
List<Note> loadedNotes(NotesRepositoryImpl repository) => switch (repository.watchNotes().value) {
      SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) => value,
      final ResultState<List<Note>, NoteFailure> other => throw TestFailure('notes are not loaded: $other'),
    };

void main() {
  final Logger silent = Logger(level: Level.off);

  test('mirrors the data source, newest first; edits keep createdAt', () async {
    DateTime clock = DateTime(2026, 11, 12, 9);
    final DatabaseNotesDataSource dataSource = DatabaseNotesDataSource(
      database: InMemoryAppDatabase(latency: Duration.zero),
      now: () => clock,
    );
    final NotesRepositoryImpl created = NotesRepositoryImpl(dataSource: dataSource, logger: silent);
    expect(created.watchNotes().value.isLoading, isTrue, reason: 'loading until the first event');
    final NotesRepositoryImpl repository = await created.init();

    expect(await repository.addNote('First'), isA<SuccessResult<void, NoteFailure>>());
    clock = DateTime(2026, 11, 12, 10);
    await repository.addNote('Second');
    await flush();
    expect(loadedNotes(repository).map((Note n) => n.text), <String>['Second', 'First']);

    final Note first = loadedNotes(repository).last;
    clock = DateTime(2026, 11, 12, 11);
    expect(await repository.updateNote(first.id, 'First, edited'), isA<SuccessResult<void, NoteFailure>>());
    await flush();
    final Note edited = loadedNotes(repository).last;
    expect(edited.text, 'First, edited');
    expect(edited.createdAt, DateTime(2026, 11, 12, 9));
    expect(edited.updatedAt, DateTime(2026, 11, 12, 11));

    await repository.deleteNote(first.id);
    await flush();
    expect(loadedNotes(repository).map((Note n) => n.text), <String>['Second']);
    await repository.dispose();
  });

  test('changing a missing note is a NoteFailure', () async {
    final NotesRepositoryImpl repository = await NotesRepositoryImpl(dataSource: memoryNotes(), logger: silent).init();

    final Result<void, NoteFailure> result = await repository.updateNote('missing', 'Text');

    expect(result, isA<FailureResult<void, NoteFailure>>());
    expect((result as FailureResult<void, NoteFailure>).failure, NoteFailure.update);
    await repository.dispose();
  });

  test('a stream error becomes FailureResultState with a NoteFailure', () async {
    final NotesRepositoryImpl repository =
        await NotesRepositoryImpl(dataSource: BrokenStreamNotesDataSource(), logger: silent).init();
    await flush();

    final ResultState<List<Note>, NoteFailure> state = repository.watchNotes().value;
    expect(state, isA<FailureResultState<List<Note>, NoteFailure>>());
    expect((state as FailureResultState<List<Note>, NoteFailure>).failure, NoteFailure.load);
    await repository.dispose();
  });

  test('exceptions become a NoteFailure', () async {
    final NotesRepositoryImpl repository =
        await NotesRepositoryImpl(dataSource: FailingNotesDataSource(), logger: silent).init();

    final Result<void, NoteFailure> result = await repository.addNote('First');

    result.when(
      success: (_) => fail('expected a failure'),
      failure: (NoteFailure failure) => expect(failure, NoteFailure.add),
    );
    await repository.dispose();
  });
}
