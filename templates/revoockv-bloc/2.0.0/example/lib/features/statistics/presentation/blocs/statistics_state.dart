import '../../domain/entities/notes_statistics.dart';
import '../../domain/entities/statistics_failure.dart';

/// What the statistics tab shows.
sealed class StatisticsState {
  const StatisticsState();
}

/// The first numbers have not arrived yet.
final class StatisticsLoading extends StatisticsState {
  /// Creates the state.
  const StatisticsLoading();
}

/// The numbers.
final class StatisticsLoaded extends StatisticsState {
  /// Numbers about the notes.
  final NotesStatistics statistics;

  /// Creates the state.
  const StatisticsLoaded(this.statistics);

  @override
  bool operator ==(Object other) => other is StatisticsLoaded && other.statistics == statistics;

  @override
  int get hashCode => statistics.hashCode;
}

/// The statistics could not be loaded.
final class StatisticsLoadFailed extends StatisticsState {
  /// What went wrong; the page turns it into text.
  final StatisticsFailure failure;

  /// Creates the state.
  const StatisticsLoadFailed(this.failure);

  @override
  bool operator ==(Object other) => other is StatisticsLoadFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
