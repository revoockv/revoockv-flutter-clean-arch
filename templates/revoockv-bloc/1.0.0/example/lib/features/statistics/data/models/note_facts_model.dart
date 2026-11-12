import '../../domain/entities/note_facts.dart';

/// The columns of a `notes` row that statistics read.
final class NoteFactsModel {
  /// Name of the table.
  static const String table = 'notes';

  static const String _textColumn = 'text';
  static const String _createdAtColumn = 'createdAt';
  static const String _updatedAtColumn = 'updatedAt';

  /// Text of the note.
  final String text;

  /// When the note was written.
  final DateTime createdAt;

  /// When the note was last changed.
  final DateTime updatedAt;

  /// Creates the model.
  const NoteFactsModel({required this.text, required this.createdAt, required this.updatedAt});

  /// Reads a row of the `notes` table.
  factory NoteFactsModel.fromRow(Map<String, Object?> row) => NoteFactsModel(
        text: row[_textColumn]! as String,
        createdAt: DateTime.parse(row[_createdAtColumn]! as String),
        updatedAt: DateTime.parse(row[_updatedAtColumn]! as String),
      );

  /// Converts the model into a domain entity.
  NoteFacts toEntity() => NoteFacts(text: text, createdAt: createdAt, updatedAt: updatedAt);
}
