import 'package:example_app/core/domain/entities/result.dart';

import '../entities/notes_statistics.dart';
import '../repositories/statistics_repository.dart';

/// Watch use case: live numbers about the notes.
final class WatchNotesStatisticsUseCase {
  final StatisticsRepository _repository;

  /// Creates the use case.
  WatchNotesStatisticsUseCase(this._repository);

  /// The statistics right away, then after every change (or the load failure).
  Stream<Result<NotesStatistics>> call() => _repository.watchNotesStatistics();
}
