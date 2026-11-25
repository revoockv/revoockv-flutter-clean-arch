import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/statistics_failure.dart';
import '../blocs/statistics_bloc.dart';
import '../blocs/statistics_state.dart';
import '../l10n/statistics_failure_text.dart';
import '../widgets/statistics_list_widget.dart';

/// Gives [StatisticsListWidget] whether the numbers are loading or failed: rebuilds only when that changes, not when a
/// number changes — each tile's wrapper does then.
final class StatisticsListWrapper extends StatelessWidget {
  /// The tiles, each with its own wrapper.
  final List<Widget> tiles;

  /// Creates the wrapper.
  const StatisticsListWrapper({required this.tiles, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<StatisticsBloc, bool>(_isLoadingOf);
    final StatisticsFailure? failure = context.select<StatisticsBloc, StatisticsFailure?>(_failureOf);
    return StatisticsListWidget(isLoading: isLoading, failureText: failure?.text, tiles: tiles);
  }

  static bool _isLoadingOf(StatisticsBloc bloc) => bloc.state is StatisticsLoading;

  static StatisticsFailure? _failureOf(StatisticsBloc bloc) => switch (bloc.state) {
    StatisticsLoadFailed(:final StatisticsFailure failure) => failure,
    _ => null,
  };
}
