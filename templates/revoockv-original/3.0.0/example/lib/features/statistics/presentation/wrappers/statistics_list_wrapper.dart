import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/notes_statistics.dart';
import '../../domain/entities/statistics_failure.dart';
import '../di/statistics_getters.dart';
import '../l10n/statistics_failure_text.dart';
import '../widgets/statistics_list_widget.dart';

/// Gives [StatisticsListWidget] whether the numbers are loading or failed: rebuilds only when that changes, not when a
/// number changes — each tile's wrapper does then.
final class StatisticsListWrapper extends WatchingWidget {
  /// The tiles, each with its own wrapper.
  final List<Widget> tiles;

  /// Creates the wrapper.
  const StatisticsListWrapper({required this.tiles, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watchPropertyValue(_isLoadingOf, target: watchNotesStatisticsUseCase());
    final StatisticsFailure? failure = watchPropertyValue(_failureOf, target: watchNotesStatisticsUseCase());
    return StatisticsListWidget(isLoading: isLoading, failureText: failure?.text, tiles: tiles);
  }

  static bool _isLoadingOf(ValueListenable<ResultState<NotesStatistics, StatisticsFailure>> statistics) =>
      statistics.value.isIdle || statistics.value.isLoading;

  static StatisticsFailure? _failureOf(ValueListenable<ResultState<NotesStatistics, StatisticsFailure>> statistics) =>
      switch (statistics.value) {
        FailureResultState<NotesStatistics, StatisticsFailure>(:final StatisticsFailure failure) => failure,
        _ => null,
      };
}
