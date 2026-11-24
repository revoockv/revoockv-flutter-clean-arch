import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../fake_notes_data_sources.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';

/// The notes of a successful result.
List<Note> notesOf(Result<List<Note>, NoteFailure> result) => switch (result) {
      SuccessResult<List<Note>, NoteFailure>(:final List<Note> value) => value,
      FailureResult<List<Note>, NoteFailure>(:final NoteFailure failure) => throw TestFailure('notes are not loaded: $failure'),
    };

void main() {
  final Logger silent = Logger(level: Level.off);

  test('watchNotes() emits newest first after every change; edits keep createdAt', () async {
    DateTime clock = DateTime(2026, 11, 12, 9);
    final NotesRepositoryImpl repository = NotesRepositoryImpl(
      dataSource: DatabaseNotesDataSource(database: InMemoryAppDatabase(latency: Duration.zero), now: () => clock),
      logger: silent,
    );

    expect(await repository.addNote('First'), isA<SuccessResult<void, NoteFailure>>());
    clock = DateTime(2026, 11, 12, 10);
    await repository.addNote('Second');
    final List<Note> notes = notesOf(await repository.watchNotes().first);
    expect(notes.map((Note n) => n.text), <String>['Second', 'First']);

    clock = DateTime(2026, 11, 12, 11);
    expect(await repository.updateNote(notes.last.id, 'First, edited'), isA<SuccessResult<void, NoteFailure>>());
    final Note edited = notesOf(await repository.watchNotes().first).last;
    expect(edited.text, 'First, edited');
    expect(edited.createdAt, DateTime(2026, 11, 12, 9));
    expect(edited.updatedAt, DateTime(2026, 11, 12, 11));

    await repository.deleteNote(edited.id);
    expect(notesOf(await repository.watchNotes().first).map((Note n) => n.text), <String>['Second']);
  });

  test('changing a missing note is an update failure', () async {
    final NotesRepositoryImpl repository = NotesRepositoryImpl(dataSource: memoryNotes(), logger: silent);

    final Result<void, NoteFailure> result = await repository.updateNote('missing', 'Text');

    expect((result as FailureResult<void, NoteFailure>).failure, NoteFailure.update);
  });

  test('a stream error becomes a load failure', () async {
    final NotesRepositoryImpl repository =
        NotesRepositoryImpl(dataSource: BrokenStreamNotesDataSource(), logger: silent);

    final Result<List<Note>, NoteFailure> first = await repository.watchNotes().first;

    expect((first as FailureResult<List<Note>, NoteFailure>).failure, NoteFailure.load);
  });

  test('exceptions of writes become failures of the action', () async {
    final NotesRepositoryImpl repository = NotesRepositoryImpl(dataSource: FailingNotesDataSource(), logger: silent);

    final Result<void, NoteFailure> result = await repository.addNote('First');

    result.when(
      success: (_) => fail('expected a failure'),
      failure: (NoteFailure failure) => expect(failure, NoteFailure.add),
    );
  });
}
