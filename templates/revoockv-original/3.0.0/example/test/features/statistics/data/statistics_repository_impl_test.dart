import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/pins/data/data_sources/database_pins_data_source.dart';
import 'package:example_app/features/pins/data/repositories/pins_repository_impl.dart';
import 'package:example_app/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:example_app/features/statistics/domain/entities/notes_statistics.dart';
import 'package:example_app/features/statistics/domain/entities/statistics_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../notes/fake_notes_data_sources.dart';

NotesStatistics statisticsOf(StatisticsRepositoryImpl repository) =>
    (repository.watchNotesStatistics().value as SuccessResultState<NotesStatistics, StatisticsFailure>).value;

void main() {
  final Logger silent = Logger(level: Level.off);

  test('counts the notes of the notes feature and the pins of the pins feature', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);
    final NotesRepositoryImpl notes =
        await NotesRepositoryImpl(dataSource: DatabaseNotesDataSource(database: database), logger: silent).init();
    final PinsRepositoryImpl pins =
        await PinsRepositoryImpl(dataSource: DatabasePinsDataSource(database: database), logger: silent).init();
    final StatisticsRepositoryImpl repository = StatisticsRepositoryImpl(notes: notes, pins: pins, logger: silent).init();

    await notes.addNote('Buy milk today');
    await notes.addNote('Call mom');
    await Future<void>.delayed(Duration.zero);
    final String first = (notes.watchNotes().value as SuccessResultState<List<Note>, NoteFailure>).value.first.id;
    await pins.togglePin(first);
    await pins.togglePin('a deleted note');
    await Future<void>.delayed(Duration.zero);

    final NotesStatistics statistics = statisticsOf(repository);
    expect(
      <int>[statistics.notes, statistics.words, statistics.addedToday, statistics.edited, statistics.pinned],
      <int>[2, 5, 2, 0, 1],
      reason: 'a pin of a note that does not exist does not count',
    );
    repository.dispose();
    await pins.dispose();
    await notes.dispose();
  });

  test('notes that cannot be loaded make the statistics fail', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);
    final NotesRepositoryImpl notes = await NotesRepositoryImpl(dataSource: BrokenStreamNotesDataSource(), logger: silent).init();
    final PinsRepositoryImpl pins =
        await PinsRepositoryImpl(dataSource: DatabasePinsDataSource(database: database), logger: silent).init();
    final StatisticsRepositoryImpl repository = StatisticsRepositoryImpl(notes: notes, pins: pins, logger: silent).init();
    await Future<void>.delayed(Duration.zero);

    final ResultState<NotesStatistics, StatisticsFailure> state = repository.watchNotesStatistics().value;
    expect((state as FailureResultState<NotesStatistics, StatisticsFailure>).failure, StatisticsFailure.load);
    repository.dispose();
    await pins.dispose();
    await notes.dispose();
  });
}
