import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/note.dart';
import '../repositories/notes_repository.dart';

/// Watch use case: the live list of notes.
final class WatchNotesUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  WatchNotesUseCase(this._repository);

  /// Returns the live list of notes (loading / notes / failure); the same instance on every call.
  ValueListenable<ResultState<List<Note>>> call() => _repository.watchNotes();
}
