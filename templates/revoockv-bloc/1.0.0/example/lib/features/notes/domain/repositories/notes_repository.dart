import 'package:example_app/core/domain/entities/result.dart';

import '../entities/note.dart';

/// Source of truth for notes.
abstract interface class NotesRepository {
  /// The notes, newest first, right away and after every change; a load error is a failure, not a stream error.
  Stream<Result<List<Note>>> watchNotes();

  /// Adds a note with [text].
  Future<Result<void>> addNote(String text);

  /// Replaces the text of the note with [id].
  Future<Result<void>> updateNote(String id, String text);

  /// Deletes the note with [id].
  Future<Result<void>> deleteNote(String id);
}
