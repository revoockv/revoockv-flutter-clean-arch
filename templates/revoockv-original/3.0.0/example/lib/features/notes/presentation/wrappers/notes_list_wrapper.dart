import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_failure.dart';
import '../di/notes_getters.dart';
import '../l10n/note_failure_text.dart';
import '../widgets/notes_list_widget.dart';
import 'note_tile_wrapper.dart';

/// Gives [NotesListWidget] the loading, the failure and the ids of the notes: rebuilds only when one of them changes,
/// not when the text of a note changes — the note's own [NoteTileWrapper] does then.
final class NotesListWrapper extends WatchingWidget {
  /// Text shown when there are no notes.
  final String emptyText;

  /// Tooltip of a note's delete button.
  final String deleteTooltip;

  /// Called with a tapped note; the page edits it.
  final ValueChanged<Note> onNoteTap;

  /// Called with the id of a note to delete; the page deletes it.
  final ValueChanged<String> onDeletePressed;

  /// Creates the wrapper.
  const NotesListWrapper({
    required this.emptyText,
    required this.deleteTooltip,
    required this.onNoteTap,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final _NotesListContent content = watchPropertyValue(_contentOf, target: watchNotesUseCase());
    return NotesListWidget(
      isLoading: content.isLoading,
      failureText: content.failure?.text,
      emptyText: emptyText,
      noteIds: content.noteIds,
      itemBuilder: (BuildContext context, String noteId) => NoteTileWrapper(
        key: ValueKey<String>(noteId),
        noteId: noteId,
        deleteTooltip: deleteTooltip,
        onTap: onNoteTap,
        onDeletePressed: onDeletePressed,
      ),
    );
  }

  static _NotesListContent _contentOf(ValueListenable<ResultState<List<Note>, NoteFailure>> notes) =>
      switch (notes.value) {
        IdleResultState<List<Note>, NoteFailure>() || LoadingResultState<List<Note>, NoteFailure>() =>
          _NotesListContent.loading,
        FailureResultState<List<Note>, NoteFailure>(:final NoteFailure failure) => _NotesListContent(failure: failure),
        SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) =>
          _NotesListContent(noteIds: value.map(_idOf).toList()),
      };

  static String _idOf(Note note) => note.id;
}

/// What the list shows, compared by value so that a new list with the same ids does not rebuild it.
final class _NotesListContent {
  static const _NotesListContent loading = _NotesListContent(isLoading: true);

  final bool isLoading;

  final NoteFailure? failure;

  final List<String> noteIds;

  const _NotesListContent({this.isLoading = false, this.failure, this.noteIds = const <String>[]});

  @override
  bool operator ==(Object other) =>
      other is _NotesListContent &&
      other.isLoading == isLoading &&
      other.failure == failure &&
      listEquals(other.noteIds, noteIds);

  @override
  int get hashCode => Object.hash(isLoading, failure, Object.hashAll(noteIds));
}
