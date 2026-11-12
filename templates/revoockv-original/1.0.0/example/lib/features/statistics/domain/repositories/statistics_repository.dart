import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/notes_statistics.dart';

/// Numbers about the notes.
abstract interface class StatisticsRepository {
  /// Live statistics — loading, the numbers, or the load failure; always the same instance.
  ValueListenable<ResultState<NotesStatistics>> watchNotesStatistics();
}
