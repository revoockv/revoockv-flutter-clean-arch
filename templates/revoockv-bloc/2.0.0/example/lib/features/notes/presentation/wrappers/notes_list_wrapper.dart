import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_failure.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_state.dart';
import '../l10n/note_failure_text.dart';
import '../widgets/notes_list_widget.dart';
import 'note_tile_wrapper.dart';

/// Gives [NotesListWidget] the loading, the failure and the ids of the notes: rebuilds only when one of them changes,
/// not when the text of a note changes — the note's own [NoteTileWrapper] does then.
final class NotesListWrapper extends StatelessWidget {
  /// Text shown when there are no notes.
  final String emptyText;

  /// Builds what is shown before the text of the note [noteId] (the page puts the pin button there).
  final Widget Function(String noteId) leadingBuilder;

  /// Tooltip of a note's delete button.
  final String deleteTooltip;

  /// Called with a tapped note; the page edits it.
  final ValueChanged<Note> onNoteTap;

  /// Called with the id of a note to delete; the page deletes it.
  final ValueChanged<String> onDeletePressed;

  /// Creates the wrapper.
  const NotesListWrapper({
    required this.emptyText,
    required this.leadingBuilder,
    required this.deleteTooltip,
    required this.onNoteTap,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotesBloc, NotesState, _NotesListContent>(
      selector: _contentOf,
      builder: (BuildContext context, _NotesListContent content) => NotesListWidget(
        isLoading: content.isLoading,
        failureText: content.failure?.text,
        emptyText: emptyText,
        noteIds: content.noteIds,
        itemBuilder: (BuildContext context, String noteId) => NoteTileWrapper(
          key: ValueKey<String>(noteId),
          noteId: noteId,
          leading: leadingBuilder(noteId),
          deleteTooltip: deleteTooltip,
          onTap: onNoteTap,
          onDeletePressed: onDeletePressed,
        ),
      ),
    );
  }

  static _NotesListContent _contentOf(NotesState state) => switch (state) {
    NotesLoading() => _NotesListContent.loading,
    NotesLoadFailed(:final NoteFailure failure) => _NotesListContent(failure: failure),
    NotesLoaded(:final List<Note> notes) => _NotesListContent(noteIds: notes.map(_idOf).toList()),
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
