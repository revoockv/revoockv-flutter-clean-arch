import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notes_statistics.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';
import '../blocs/statistics_bloc.dart';
import '../blocs/statistics_event.dart';
import '../blocs/statistics_state.dart';
import '../widgets/statistic_tile_widget.dart';

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

/// The numbers, or a progress indicator, or the load error.
final class _StatisticsViewWidget extends StatelessWidget {
  static const String _notesLabel = 'Notes';
  static const String _wordsLabel = 'Words';
  static const String _addedTodayLabel = 'Added today';
  static const String _editedLabel = 'Edited';

  const _StatisticsViewWidget();

  @override
  Widget build(BuildContext context) {
    final StatisticsState state = context.watch<StatisticsBloc>().state;
    return switch (state) {
      StatisticsLoading() => const Center(child: CircularProgressIndicator()),
      StatisticsLoadFailed(:final String message) => Center(child: Text(message)),
      StatisticsLoaded(:final NotesStatistics statistics) => ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: <Widget>[
            StatisticTileWidget(label: _notesLabel, value: statistics.notes),
            StatisticTileWidget(label: _wordsLabel, value: statistics.words),
            StatisticTileWidget(label: _addedTodayLabel, value: statistics.addedToday),
            StatisticTileWidget(label: _editedLabel, value: statistics.edited),
          ],
        ),
    };
  }
}
