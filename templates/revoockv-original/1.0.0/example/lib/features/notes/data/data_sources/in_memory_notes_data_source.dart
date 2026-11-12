import 'dart:async';

import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:uuid/uuid.dart';

import '../models/note_model.dart';
import 'notes_data_source.dart';

/// Keeps notes in memory; a stand-in for a database or an API.
final class InMemoryNotesDataSource implements NotesDataSource, DisposableResource {
  /// Generator of note ids: a random UUID v4, unique across restarts and devices.
  static const Uuid _uuid = Uuid();

  final List<NoteModel> _notes = <NoteModel>[];

  final StreamController<List<NoteModel>> _changes = StreamController<List<NoteModel>>.broadcast();

  /// Emits the current notes right away, then every change; subscribes synchronously, so no change is lost.
  @override
  Stream<List<NoteModel>> watchNotes() => Stream<List<NoteModel>>.multi(_onListen);

  @override
  Future<NoteModel> add(String text) async {
    final NoteModel note = NoteModel(id: _uuid.v4(), text: text);
    _notes.add(note);
    _emit();
    return note;
  }

  @override
  Future<void> delete(String id) async {
    _notes.removeWhere((NoteModel note) => note.id == id);
    _emit();
  }

  /// Closes the change stream. Called by DI only.
  @override
  Future<void> dispose() => _changes.close();

  void _emit() {
    _changes.add(List<NoteModel>.unmodifiable(_notes));
  }

  void _onListen(MultiStreamController<List<NoteModel>> listener) {
    listener.add(List<NoteModel>.unmodifiable(_notes));
    final StreamSubscription<List<NoteModel>> sub = _changes.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = sub.cancel;
  }
}
