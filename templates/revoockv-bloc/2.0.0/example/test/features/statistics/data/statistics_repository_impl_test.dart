import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
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

final Logger silent = Logger(level: Level.off);

/// Statistics over the notes and the pins of [database]; [notes] replaces the notes' data source when given.
StatisticsRepositoryImpl statisticsOver(InMemoryAppDatabase database, {NotesDataSource? notes}) =>
    StatisticsRepositoryImpl(
      notes: NotesRepositoryImpl(
        dataSource: notes ?? DatabaseNotesDataSource(database: database),
        logger: silent,
      ),
      pins: PinsRepositoryImpl(
        dataSource: DatabasePinsDataSource(database: database),
        logger: silent,
      ),
      logger: silent,
    );

void main() {
  test('counts the notes of the notes feature and the pins of the pins feature', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);
    final NotesRepositoryImpl notes = NotesRepositoryImpl(
      dataSource: DatabaseNotesDataSource(database: database),
      logger: silent,
    );
    final PinsRepositoryImpl pins = PinsRepositoryImpl(
      dataSource: DatabasePinsDataSource(database: database),
      logger: silent,
    );
    await notes.addNote('Buy milk today');
    await notes.addNote('Call mom');
    final List<Note> stored = (await notes.watchNotes().first as SuccessResult<List<Note>, NoteFailure>).value;
    await pins.togglePin(stored.first.id);
    await pins.togglePin('a deleted note');

    final Result<NotesStatistics, StatisticsFailure> result = await statisticsOver(
      database,
    ).watchNotesStatistics().first;

    final NotesStatistics statistics = (result as SuccessResult<NotesStatistics, StatisticsFailure>).value;
    expect(
      <int>[statistics.notes, statistics.words, statistics.addedToday, statistics.edited, statistics.pinned],
      <int>[2, 5, 2, 0, 1],
      reason: 'a pin of a note that does not exist does not count',
    );
  });

  test('notes that cannot be loaded make the statistics fail', () async {
    final StatisticsRepositoryImpl repository = statisticsOver(
      InMemoryAppDatabase(latency: Duration.zero),
      notes: BrokenStreamNotesDataSource(),
    );

    final Result<NotesStatistics, StatisticsFailure> result = await repository.watchNotesStatistics().first;

    expect((result as FailureResult<NotesStatistics, StatisticsFailure>).failure, StatisticsFailure.load);
  });
}
