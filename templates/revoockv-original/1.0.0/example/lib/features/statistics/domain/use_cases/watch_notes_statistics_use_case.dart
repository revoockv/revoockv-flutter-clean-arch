import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/notes_statistics.dart';
import '../repositories/statistics_repository.dart';

/// Watch use case: live numbers about the notes.
final class WatchNotesStatisticsUseCase {
  final StatisticsRepository _repository;

  /// Creates the use case.
  WatchNotesStatisticsUseCase(this._repository);

  /// Returns the live statistics (loading / numbers / failure); the same instance on every call.
  ValueListenable<ResultState<NotesStatistics>> call() => _repository.watchNotesStatistics();
}
