import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/notes_statistics.dart';
import '../../domain/entities/statistics_failure.dart';
import '../di/statistics_getters.dart';
import '../widgets/statistic_tile_widget.dart';

/// Gives [StatisticTileWidget] one number of the statistics: rebuilds only when that number changes.
final class StatisticTileWrapper extends WatchingWidget {
  /// What the number counts.
  final String label;

  /// Picks the number of this tile from the statistics.
  final int Function(NotesStatistics statistics) countOf;

  /// Creates the wrapper.
  const StatisticTileWrapper({required this.label, required this.countOf, super.key});

  @override
  Widget build(BuildContext context) {
    final int value = watchPropertyValue(_valueOf, target: watchNotesStatisticsUseCase());
    return StatisticTileWidget(label: label, value: value);
  }

  int _valueOf(ValueListenable<ResultState<NotesStatistics, StatisticsFailure>> statistics) =>
      switch (statistics.value) {
        SuccessResultState<NotesStatistics, StatisticsFailure>(:final NotesStatistics value) => countOf(value),
        _ => 0,
      };
}
