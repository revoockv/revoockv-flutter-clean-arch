import 'package:example_app/core/domain/entities/result.dart';

import '../entities/note.dart';

/// Source of truth for notes.
abstract interface class NotesRepository {
  /// The notes right away, then after every change; a load error is a failure, not a stream error.
  Stream<Result<List<Note>>> watchNotes();

  /// Adds a note with [text].
  Future<Result<void>> addNote(String text);

  /// Deletes the note with [id].
  Future<Result<void>> deleteNote(String id);
}
