/// A short text note.
final class Note {
  /// Unique id of the note.
  final String id;

  /// Text of the note.
  final String text;

  /// When the note was written.
  final DateTime createdAt;

  /// When the note was last changed (equals [createdAt] until it is edited).
  final DateTime updatedAt;

  /// Creates a note.
  const Note({required this.id, required this.text, required this.createdAt, required this.updatedAt});

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, text, createdAt, updatedAt);
}
