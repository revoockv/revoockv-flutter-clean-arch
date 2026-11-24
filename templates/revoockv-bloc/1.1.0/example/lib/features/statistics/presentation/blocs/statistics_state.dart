import '../../domain/entities/notes_statistics.dart';

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
  /// Human-readable reason.
  final String message;

  /// Creates the state.
  const StatisticsLoadFailed(this.message);

  @override
  bool operator ==(Object other) => other is StatisticsLoadFailed && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
