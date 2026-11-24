import 'package:bloc_test/bloc_test.dart';
import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/features/statistics/data/data_sources/database_statistics_data_source.dart';
import 'package:example_app/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:example_app/features/statistics/domain/entities/notes_statistics.dart';
import 'package:example_app/features/statistics/domain/use_cases/watch_notes_statistics_use_case.dart';
import 'package:example_app/features/statistics/presentation/blocs/statistics_bloc.dart';
import 'package:example_app/features/statistics/presentation/blocs/statistics_event.dart';
import 'package:example_app/features/statistics/presentation/blocs/statistics_state.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../../app_test_app.dart';
import '../../../settle.dart';

void main() {
  blocTest<StatisticsBloc, StatisticsState>(
    'follows the statistics after StatisticsSubscribed',
    build: () => StatisticsBloc(
      watchNotesStatisticsUseCase: WatchNotesStatisticsUseCase(
        StatisticsRepositoryImpl(
          dataSource: DatabaseStatisticsDataSource(database: InMemoryAppDatabase(latency: Duration.zero)),
          logger: Logger(level: Level.off),
        ),
      ),
    ),
    act: (StatisticsBloc bloc) => bloc.add(const StatisticsSubscribed()),
    expect: () => const <StatisticsState>[
      StatisticsLoaded(NotesStatistics(notes: 0, words: 0, addedToday: 0, edited: 0)),
    ],
  );

  testWidgets('shows the numbers of an empty app', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(const Scaffold(body: StatisticsPage())));
    await settle(tester);

    for (final String label in <String>['Notes', 'Words', 'Added today', 'Edited']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    expect(find.text('0'), findsNWidgets(4));
  });
}
