import '../models/note_model.dart';

/// Storage of notes.
abstract interface class NotesDataSource {
  /// Emits the full list of notes after every change.
  Stream<List<NoteModel>> watchNotes();

  /// Stores a new note with [text] and returns it with the id the storage gave it.
  Future<NoteModel> add(String text);

  /// Removes the note with [id].
  Future<void> delete(String id);
}
