import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/statistics/data/data_sources/database_statistics_data_source.dart';
import 'package:example_app/features/statistics/data/data_sources/statistics_data_source.dart';
import 'package:example_app/features/statistics/data/models/note_facts_model.dart';
import 'package:example_app/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:example_app/features/statistics/domain/entities/notes_statistics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Data source whose stream fails right away.
final class BrokenStatisticsDataSource implements StatisticsDataSource {
  @override
  Stream<List<NoteFactsModel>> watchNoteFacts() => Stream<List<NoteFactsModel>>.error(Exception('db closed'));
}

void main() {
  final Logger silent = Logger(level: Level.off);

  test('counts the notes another feature writes to the same database', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);
    final StatisticsRepositoryImpl repository =
        StatisticsRepositoryImpl(dataSource: DatabaseStatisticsDataSource(database: database), logger: silent);

    await DatabaseNotesDataSource(database: database).add('Buy milk today');
    final Result<NotesStatistics> result = await repository.watchNotesStatistics().first;

    expect((result as SuccessResult<NotesStatistics>).value,
        const NotesStatistics(notes: 1, words: 3, addedToday: 1, edited: 0));
  });

  test('a stream error becomes a human-readable failure', () async {
    final StatisticsRepositoryImpl repository =
        StatisticsRepositoryImpl(dataSource: BrokenStatisticsDataSource(), logger: silent);

    final Result<NotesStatistics> result = await repository.watchNotesStatistics().first;

    expect((result as FailureResult<NotesStatistics>).error, 'Could not load the statistics');
  });
}
