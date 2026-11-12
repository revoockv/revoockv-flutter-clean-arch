import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/notes_statistics.dart';
import '../di/statistics_getters.dart';
import '../widgets/statistic_tile_widget.dart';

/// Statistics tab: live numbers about the notes.
final class StatisticsPage extends WatchingWidget {
  static const String _notesLabel = 'Notes';
  static const String _wordsLabel = 'Words';
  static const String _addedTodayLabel = 'Added today';
  static const String _editedLabel = 'Edited';

  /// Creates the page.
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ResultState<NotesStatistics> statistics = watch(watchNotesStatisticsUseCase()).value;

    return switch (statistics) {
      IdleResultState<NotesStatistics>() || LoadingResultState<NotesStatistics>() =>
        const Center(child: CircularProgressIndicator()),
      FailureResultState<NotesStatistics>(:final String message) => Center(child: Text(message)),
      SuccessResultState<NotesStatistics>(:final NotesStatistics value) => ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: <Widget>[
            StatisticTileWidget(label: _notesLabel, value: value.notes),
            StatisticTileWidget(label: _wordsLabel, value: value.words),
            StatisticTileWidget(label: _addedTodayLabel, value: value.addedToday),
            StatisticTileWidget(label: _editedLabel, value: value.edited),
          ],
        ),
    };
  }
}
