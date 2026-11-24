import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notes_statistics.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';
import '../blocs/statistics_bloc.dart';
import '../blocs/statistics_event.dart';
import '../wrappers/statistic_tile_wrapper.dart';
import '../wrappers/statistics_list_wrapper.dart';

/// Statistics tab: creates its bloc from the feature's use case and shows the live numbers.
final class StatisticsPage extends StatelessWidget {
  /// Creates the page.
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BlocProvider<StatisticsBloc>(create: _createStatisticsBloc, child: _StatisticsViewWidget());
  }

  static StatisticsBloc _createStatisticsBloc(BuildContext context) =>
      StatisticsBloc(watchNotesStatisticsUseCase: context.read<WatchNotesStatisticsUseCase>())
        ..add(const StatisticsSubscribed());
}

/// The numbers: holds the labels; never rebuilds itself — every tile's wrapper selects its own number.
final class _StatisticsViewWidget extends StatelessWidget {
  static const String _notesLabel = 'Notes';
  static const String _wordsLabel = 'Words';
  static const String _addedTodayLabel = 'Added today';
  static const String _editedLabel = 'Edited';
  static const String _pinnedLabel = 'Pinned';

  const _StatisticsViewWidget();

  @override
  Widget build(BuildContext context) {
    return const StatisticsListWrapper(
      tiles: <Widget>[
        StatisticTileWrapper(label: _notesLabel, countOf: _notesOf),
        StatisticTileWrapper(label: _wordsLabel, countOf: _wordsOf),
        StatisticTileWrapper(label: _addedTodayLabel, countOf: _addedTodayOf),
        StatisticTileWrapper(label: _editedLabel, countOf: _editedOf),
        StatisticTileWrapper(label: _pinnedLabel, countOf: _pinnedOf),
      ],
    );
  }

  static int _notesOf(NotesStatistics statistics) => statistics.notes;

  static int _wordsOf(NotesStatistics statistics) => statistics.words;

  static int _addedTodayOf(NotesStatistics statistics) => statistics.addedToday;

  static int _editedOf(NotesStatistics statistics) => statistics.edited;

  static int _pinnedOf(NotesStatistics statistics) => statistics.pinned;
}
