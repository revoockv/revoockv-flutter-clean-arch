import 'package:example_app/core/data/data_sources/app_database.dart';

import '../../domain/entities/note.dart';

/// Storage format of a note: a row of the `notes` table.
final class NoteModel {
  /// Name of the table.
  static const String table = 'notes';

  static const String _textColumn = 'text';
  static const String _createdAtColumn = 'createdAt';
  static const String _updatedAtColumn = 'updatedAt';

  /// Unique id of the note.
  final String id;

  /// Text of the note.
  final String text;

  /// When the note was written.
  final DateTime createdAt;

  /// When the note was last changed.
  final DateTime updatedAt;

  /// Creates a note model.
  const NoteModel({required this.id, required this.text, required this.createdAt, required this.updatedAt});

  /// Reads a row of the `notes` table.
  factory NoteModel.fromRow(Map<String, Object?> row) => NoteModel(
        id: row[AppDatabase.idColumn]! as String,
        text: row[_textColumn]! as String,
        createdAt: DateTime.parse(row[_createdAtColumn]! as String),
        updatedAt: DateTime.parse(row[_updatedAtColumn]! as String),
      );

  /// Creates a model from a domain [entity].
  factory NoteModel.fromEntity(Note entity) =>
      NoteModel(id: entity.id, text: entity.text, createdAt: entity.createdAt, updatedAt: entity.updatedAt);

  /// The row to store.
  Map<String, Object?> toRow() => <String, Object?>{
        AppDatabase.idColumn: id,
        _textColumn: text,
        _createdAtColumn: createdAt.toIso8601String(),
        _updatedAtColumn: updatedAt.toIso8601String(),
      };

  /// Converts the model into a domain entity.
  Note toEntity() => Note(id: id, text: text, createdAt: createdAt, updatedAt: updatedAt);
}
