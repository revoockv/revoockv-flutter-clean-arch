import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:uuid/uuid.dart';

import '../models/note_model.dart';
import 'notes_data_source.dart';

/// Notes in the `notes` table of the [AppDatabase].
final class DatabaseNotesDataSource implements NotesDataSource {
  /// Generator of note ids: a random UUID v4, unique across restarts and devices.
  static const Uuid _uuid = Uuid();

  final AppDatabase _database;

  final DateTime Function() _now;

  /// Creates the data source; `now` is the clock (tests pass a fixed one).
  DatabaseNotesDataSource({required this._database, this._now = DateTime.now});

  @override
  Stream<List<NoteModel>> watchNotes() => _database.watchTable(NoteModel.table).map(_toModels);

  @override
  Future<NoteModel> add(String text) async {
    final DateTime now = _now();
    final NoteModel note = NoteModel(id: _uuid.v4(), text: text, createdAt: now, updatedAt: now);
    await _database.insert(NoteModel.table, note.toRow());
    return note;
  }

  @override
  Future<NoteModel> update(String id, String text) async {
    final List<NoteModel> notes = await watchNotes().first;
    final NoteModel old = notes.firstWhere(
      (NoteModel note) => note.id == id,
      orElse: () => throw RowNotFoundException(NoteModel.table, id),
    );
    final NoteModel note = NoteModel(id: id, text: text, createdAt: old.createdAt, updatedAt: _now());
    await _database.update(NoteModel.table, id, note.toRow());
    return note;
  }

  @override
  Future<void> delete(String id) => _database.delete(NoteModel.table, id);

  static List<NoteModel> _toModels(List<Map<String, Object?>> rows) => rows.map(NoteModel.fromRow).toList();
}
