/// What statistics need to know about one note.
final class NoteFacts {
  /// Text of the note.
  final String text;

  /// When the note was written.
  final DateTime createdAt;

  /// When the note was last changed.
  final DateTime updatedAt;

  /// Creates the facts.
  const NoteFacts({required this.text, required this.createdAt, required this.updatedAt});
}
