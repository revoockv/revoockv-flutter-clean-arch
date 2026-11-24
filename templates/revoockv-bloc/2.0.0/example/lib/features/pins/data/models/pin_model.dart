import 'package:example_app/core/data/data_sources/app_database.dart';

/// Storage format of a pin: a row of the `pins` table, keyed by the note id.
final class PinModel {
  /// Name of the table.
  static const String table = 'pins';

  /// Id of the pinned note.
  final String noteId;

  /// Creates a pin model.
  const PinModel({required this.noteId});

  /// Reads a row of the `pins` table.
  factory PinModel.fromRow(Map<String, Object?> row) => PinModel(noteId: row[AppDatabase.idColumn]! as String);

  /// The row to store.
  Map<String, Object?> toRow() => <String, Object?>{AppDatabase.idColumn: noteId};
}
