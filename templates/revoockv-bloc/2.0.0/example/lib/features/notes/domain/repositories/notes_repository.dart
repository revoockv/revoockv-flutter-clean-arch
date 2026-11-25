import 'package:example_app/core/domain/entities/result.dart';

import '../entities/note.dart';
import '../entities/note_failure.dart';

/// Source of truth for notes.
abstract interface class NotesRepository {
  /// The notes, newest first, right away and after every change; a load error is a failure, not a stream error.
  Stream<Result<List<Note>, NoteFailure>> watchNotes();

  /// Adds a note with [text].
  Future<Result<void, NoteFailure>> addNote(String text);

  /// Replaces the text of the note with [id].
  Future<Result<void, NoteFailure>> updateNote(String id, String text);

  /// Deletes the note with [id].
  Future<Result<void, NoteFailure>> deleteNote(String id);
}
