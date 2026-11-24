/// What the statistics need to know about one note — no more.
final class NoteFacts {
  /// Text of the note (its words are counted).
  final String text;

  /// When the note was written.
  final DateTime createdAt;

  /// When the note was last changed.
  final DateTime updatedAt;

  /// Whether the note is pinned.
  final bool isPinned;

  /// Creates the facts.
  const NoteFacts({required this.text, required this.createdAt, required this.updatedAt, required this.isPinned});
}
