import '../models/note_model.dart';

/// Storage of notes.
abstract interface class NotesDataSource {
  /// Emits the full list of notes right away, then after every change.
  Stream<List<NoteModel>> watchNotes();

  /// Stores a new note with [text] and returns it with the id and times the storage gave it.
  Future<NoteModel> add(String text);

  /// Replaces the text of the note with [id] and returns the changed note.
  Future<NoteModel> update(String id, String text);

  /// Removes the note with [id].
  Future<void> delete(String id);
}
