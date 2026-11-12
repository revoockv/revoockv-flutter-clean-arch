/// What the statistics are asked to do.
sealed class StatisticsEvent {
  const StatisticsEvent();
}

/// The statistics start following the notes.
final class StatisticsSubscribed extends StatisticsEvent {
  /// Creates the event.
  const StatisticsSubscribed();
}
