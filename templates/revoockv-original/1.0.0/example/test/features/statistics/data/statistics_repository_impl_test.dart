import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
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
    final StatisticsRepositoryImpl repository = await StatisticsRepositoryImpl(
      dataSource: DatabaseStatisticsDataSource(database: database),
      logger: silent,
    ).init();

    await DatabaseNotesDataSource(database: database).add('Buy milk today');
    await Future<void>.delayed(Duration.zero);

    final ResultState<NotesStatistics> state = repository.watchNotesStatistics().value;
    expect(state, isA<SuccessResultState<NotesStatistics>>());
    final NotesStatistics statistics = (state as SuccessResultState<NotesStatistics>).value;
    expect(<int>[statistics.notes, statistics.words, statistics.addedToday, statistics.edited], <int>[1, 3, 1, 0]);
    await repository.dispose();
  });

  test('a stream error becomes a human-readable failure', () async {
    final StatisticsRepositoryImpl repository =
        await StatisticsRepositoryImpl(dataSource: BrokenStatisticsDataSource(), logger: silent).init();
    await Future<void>.delayed(Duration.zero);

    final ResultState<NotesStatistics> state = repository.watchNotesStatistics().value;
    expect((state as FailureResultState<NotesStatistics>).message, 'Could not load the statistics');
    await repository.dispose();
  });
}
