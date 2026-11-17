import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/notes_statistics.dart';
import '../di/statistics_getters.dart';
import '../widgets/statistic_tile_widget.dart';
import '../../domain/entities/statistics_failure.dart';
import '../l10n/statistics_failure_text.dart';

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
    final ResultState<NotesStatistics, StatisticsFailure> statistics = watch(watchNotesStatisticsUseCase()).value;

    return switch (statistics) {
      IdleResultState<NotesStatistics, StatisticsFailure>() ||
      LoadingResultState<NotesStatistics, StatisticsFailure>() => const Center(child: CircularProgressIndicator()),
      FailureResultState<NotesStatistics, StatisticsFailure>(:final StatisticsFailure failure) => Center(
        child: Text(failure.text),
      ),
      SuccessResultState<NotesStatistics, StatisticsFailure>(:final NotesStatistics value) => ListView(
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
