import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notes_statistics.dart';
import '../blocs/statistics_bloc.dart';
import '../blocs/statistics_state.dart';
import '../widgets/statistic_tile_widget.dart';

/// Gives [StatisticTileWidget] one number of the statistics: rebuilds only when that number changes.
final class StatisticTileWrapper extends StatelessWidget {
  /// What the number counts.
  final String label;

  /// Picks the number of this tile from the statistics.
  final int Function(NotesStatistics statistics) countOf;

  /// Creates the wrapper.
  const StatisticTileWrapper({required this.label, required this.countOf, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatisticsBloc, StatisticsState, int>(
      selector: _valueOf,
      builder: (BuildContext context, int value) => StatisticTileWidget(label: label, value: value),
    );
  }

  int _valueOf(StatisticsState state) => switch (state) {
    StatisticsLoaded(:final NotesStatistics statistics) => countOf(statistics),
    _ => 0,
  };
}
