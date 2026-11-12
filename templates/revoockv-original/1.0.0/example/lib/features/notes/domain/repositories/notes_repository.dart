import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/note.dart';

/// Source of truth for notes.
abstract interface class NotesRepository {
  /// Live list of notes — loading, the notes, or the load failure; always the same instance.
  ValueListenable<ResultState<List<Note>>> watchNotes();

  /// Adds a note with [text].
  Future<Result<void>> addNote(String text);

  /// Deletes the note with [id].
  Future<Result<void>> deleteNote(String id);
}
