/// A short text note.
final class Note {
  /// Unique id of the note.
  final String id;

  /// Text of the note.
  final String text;

  /// Creates a note.
  const Note({required this.id, required this.text});

  @override
  bool operator ==(Object other) => other is Note && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(id, text);
}
