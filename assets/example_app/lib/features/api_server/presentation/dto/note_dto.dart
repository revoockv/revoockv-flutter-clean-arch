import 'package:example_app/features/notes/domain/entities/note.dart';

/// API format of a note: `{"id": "...", "text": "..."}`.
final class NoteDto {
  static const String _idKey = 'id';
  static const String _textKey = 'text';

  /// Unique id of the note.
  final String id;

  /// Text of the note.
  final String text;

  /// Creates the DTO.
  const NoteDto({required this.id, required this.text});

  /// Creates the DTO from a domain [entity].
  factory NoteDto.fromEntity(Note entity) => NoteDto(id: entity.id, text: entity.text);

  /// Converts the DTO into JSON.
  Map<String, Object?> toJson() => <String, Object?>{_idKey: id, _textKey: text};
}
