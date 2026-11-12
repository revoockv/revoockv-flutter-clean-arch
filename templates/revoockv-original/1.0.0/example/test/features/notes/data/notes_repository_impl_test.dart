import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/data/data_sources/in_memory_notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../fake_notes_data_sources.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

/// The loaded notes of [repository]; fails the test when they are not loaded.
List<Note> loadedNotes(NotesRepositoryImpl repository) => switch (repository.watchNotes().value) {
      SuccessResultState<List<Note>>(:final List<Note> value) => value,
      final ResultState<List<Note>> other => throw TestFailure('notes are not loaded: $other'),
    };

void main() {
  final Logger silent = Logger(level: Level.off);

  test('mirrors the data source into watchNotes()', () async {
    final InMemoryNotesDataSource dataSource = InMemoryNotesDataSource();
    final NotesRepositoryImpl created = NotesRepositoryImpl(dataSource: dataSource, logger: silent);
    expect(created.watchNotes().value.isLoading, isTrue, reason: 'loading until the first event');
    final NotesRepositoryImpl repository = await created.init();

    expect(await repository.addNote('First'), isA<SuccessResult<void>>());
    await flush();
    final List<Note> notes = loadedNotes(repository);
    expect(notes.map((Note n) => n.text), <String>['First']);

    await repository.deleteNote(notes.single.id);
    await flush();
    expect(loadedNotes(repository), isEmpty);

    await repository.dispose();
    await dataSource.dispose();
  });

  test('the data source gives every note its own id', () async {
    final InMemoryNotesDataSource dataSource = InMemoryNotesDataSource();
    final NotesRepositoryImpl repository =
        await NotesRepositoryImpl(dataSource: dataSource, logger: silent).init();

    await repository.addNote('Same');
    await repository.addNote('Same');
    await flush();
    final Set<String> ids = loadedNotes(repository).map((Note n) => n.id).toSet();
    expect(ids, hasLength(2));

    await repository.dispose();
    await dataSource.dispose();
  });

  test('a stream error becomes FailureResultState with a human-readable message', () async {
    final NotesRepositoryImpl repository =
        await NotesRepositoryImpl(dataSource: BrokenStreamNotesDataSource(), logger: silent).init();
    await flush();

    final ResultState<List<Note>> state = repository.watchNotes().value;
    expect(state, isA<FailureResultState<List<Note>>>());
    expect((state as FailureResultState<List<Note>>).message, 'Could not load the notes');
    await repository.dispose();
  });

  test('exceptions become a human-readable failure', () async {
    final NotesRepositoryImpl repository =
        await NotesRepositoryImpl(dataSource: FailingNotesDataSource(), logger: silent).init();

    final Result<void> result = await repository.addNote('First');

    result.when(
      success: (_) => fail('expected a failure'),
      failure: (String error) => expect(error, 'Could not add the note'),
    );
    await repository.dispose();
  });
}
