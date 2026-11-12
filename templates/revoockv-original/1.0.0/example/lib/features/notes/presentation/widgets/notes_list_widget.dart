import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note.dart';
import '../di/notes_getters.dart';
import 'note_tile_widget.dart';

/// Live list of notes: a progress indicator while loading, the load error, or the notes.
/// Forwards delete requests to [onDelete].
final class NotesListWidget extends WatchingWidget {
  /// Text shown when there are no notes.
  static const String _emptyText = 'No notes yet';

  /// Called with the id of the note to delete.
  final ValueChanged<String> onDelete;

  /// Creates the list.
  const NotesListWidget({required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final ResultState<List<Note>> notes = watch(watchNotesUseCase()).value;

    return switch (notes) {
      IdleResultState<List<Note>>() || LoadingResultState<List<Note>>() =>
        const Center(child: CircularProgressIndicator()),
      FailureResultState<List<Note>>(:final String message) => Center(child: Text(message)),
      SuccessResultState<List<Note>>(:final List<Note> value) when value.isEmpty =>
        const Center(child: Text(_emptyText)),
      SuccessResultState<List<Note>>(:final List<Note> value) => ListView(
          children: <Widget>[
            for (final Note note in value) NoteTileWidget(note: note, onDelete: onDelete),
          ],
        ),
    };
  }
}
