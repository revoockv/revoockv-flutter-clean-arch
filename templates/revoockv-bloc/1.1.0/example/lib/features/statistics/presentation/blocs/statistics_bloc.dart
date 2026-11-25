import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notes_statistics.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

/// The statistics tab: follows [WatchNotesStatisticsUseCase] and turns every result into a [StatisticsState].
final class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final WatchNotesStatisticsUseCase _watchNotesStatisticsUseCase;

  /// Creates the bloc; it starts with [StatisticsLoading] and follows the notes after [StatisticsSubscribed].
  StatisticsBloc({required this._watchNotesStatisticsUseCase}) : super(const StatisticsLoading()) {
    on<StatisticsSubscribed>(_onSubscribed);
  }

  Future<void> _onSubscribed(StatisticsSubscribed event, Emitter<StatisticsState> emit) =>
      emit.forEach<Result<NotesStatistics>>(_watchNotesStatisticsUseCase(), onData: _toState);

  static StatisticsState _toState(Result<NotesStatistics> result) => switch (result) {
        SuccessResult<NotesStatistics>(:final NotesStatistics value) => StatisticsLoaded(value),
        FailureResult<NotesStatistics>(:final String error) => StatisticsLoadFailed(error),
      };
}
