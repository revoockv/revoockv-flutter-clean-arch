import 'package:example_app/core/domain/entities/result.dart';

import '../entities/notes_statistics.dart';

/// Numbers about the notes.
abstract interface class StatisticsRepository {
  /// The statistics right away, then after every change; a load error is a failure, not a stream error.
  Stream<Result<NotesStatistics>> watchNotesStatistics();
}
