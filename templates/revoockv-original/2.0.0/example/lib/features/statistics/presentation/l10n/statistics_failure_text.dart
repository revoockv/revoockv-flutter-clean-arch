import '../../domain/entities/statistics_failure.dart';

/// The text of a [StatisticsFailure] shown to the user.
extension StatisticsFailureText on StatisticsFailure {
  static const String _load = 'Could not load the statistics';

  /// The human-readable text of this failure.
  String get text => switch (this) {
    StatisticsFailure.load => _load,
  };
}
