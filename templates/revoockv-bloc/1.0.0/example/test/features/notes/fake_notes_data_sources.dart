import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/data/models/note_model.dart';

/// The real data source over a database without latency.
DatabaseNotesDataSource memoryNotes() => DatabaseNotesDataSource(database: InMemoryAppDatabase(latency: Duration.zero));

/// Data source whose writes always fail.
final class FailingNotesDataSource implements NotesDataSource {
  @override
  Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.value(const <NoteModel>[]);

  @override
  Future<NoteModel> add(String text) async => throw Exception('disk full');

  @override
  Future<NoteModel> update(String id, String text) async => throw Exception('disk full');

  @override
  Future<void> delete(String id) async => throw Exception('disk full');
}

/// Data source whose stream fails right away.
final class BrokenStreamNotesDataSource implements NotesDataSource {
  @override
  Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.error(Exception('db closed'));

  @override
  Future<NoteModel> add(String text) async => throw Exception('db closed');

  @override
  Future<NoteModel> update(String id, String text) async => throw Exception('db closed');

  @override
  Future<void> delete(String id) async {}
}
