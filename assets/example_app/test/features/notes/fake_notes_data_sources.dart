import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/data/models/note_model.dart';

/// Data source whose writes always fail.
final class FailingNotesDataSource implements NotesDataSource {
  @override
  Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.value(const <NoteModel>[]);

  @override
  Future<NoteModel> add(String text) async => throw Exception('disk full');

  @override
  Future<void> delete(String id) async => throw Exception('disk full');
}

/// Data source whose stream fails right away.
final class BrokenStreamNotesDataSource implements NotesDataSource {
  @override
  Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.error(Exception('db closed'));

  @override
  Future<NoteModel> add(String text) async => NoteModel(id: text, text: text);

  @override
  Future<void> delete(String id) async {}
}
