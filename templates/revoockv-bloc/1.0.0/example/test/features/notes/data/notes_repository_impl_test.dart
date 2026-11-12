import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/data/data_sources/in_memory_notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../fake_notes_data_sources.dart';

/// The texts of a successful list of notes.
List<String> texts(Result<List<Note>> result) => switch (result) {
      SuccessResult<List<Note>>(:final List<Note> value) => value.map((Note n) => n.text).toList(),
      FailureResult<List<Note>>(:final String error) => throw TestFailure('notes are not loaded: $error'),
    };

void main() {
  final Logger silent = Logger(level: Level.off);

  test('watchNotes() emits the notes right away, then after every change', () async {
    final InMemoryNotesDataSource dataSource = InMemoryNotesDataSource();
    final NotesRepositoryImpl repository = NotesRepositoryImpl(dataSource: dataSource, logger: silent);
    final List<Result<List<Note>>> seen = <Result<List<Note>>>[];
    final subscription = repository.watchNotes().listen(seen.add);

    expect(await repository.addNote('First'), isA<SuccessResult<void>>());
    await Future<void>.delayed(Duration.zero);

    expect(seen.map(texts), <List<String>>[<String>[], <String>['First']]);
    await subscription.cancel();
    await dataSource.dispose();
  });

  test('a stream error becomes a human-readable failure', () async {
    final NotesRepositoryImpl repository =
        NotesRepositoryImpl(dataSource: BrokenStreamNotesDataSource(), logger: silent);

    final Result<List<Note>> first = await repository.watchNotes().first;

    expect(first, isA<FailureResult<List<Note>>>());
    expect((first as FailureResult<List<Note>>).error, 'Could not load the notes');
  });

  test('exceptions of writes become a human-readable failure', () async {
    final NotesRepositoryImpl repository = NotesRepositoryImpl(dataSource: FailingNotesDataSource(), logger: silent);

    final Result<void> result = await repository.addNote('First');

    result.when(
      success: (_) => fail('expected a failure'),
      failure: (String error) => expect(error, 'Could not add the note'),
    );
  });
}
