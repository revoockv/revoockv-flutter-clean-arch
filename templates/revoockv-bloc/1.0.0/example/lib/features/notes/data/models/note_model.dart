import '../../domain/entities/note.dart';

/// Storage format of a note.
final class NoteModel {
  /// Unique id of the note.
  final String id;

  /// Text of the note.
  final String text;

  /// Creates a note model.
  const NoteModel({required this.id, required this.text});

  /// Creates a model from a domain [entity].
  factory NoteModel.fromEntity(Note entity) => NoteModel(id: entity.id, text: entity.text);

  /// Converts the model into a domain entity.
  Note toEntity() => Note(id: id, text: text);
}
