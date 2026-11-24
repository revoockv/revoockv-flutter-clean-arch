import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/note.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_state.dart';
import '../widgets/note_tile_widget.dart';

/// Gives [NoteTileWidget] its note: rebuilds only when this note changes, not when another one does.
final class NoteTileWrapper extends StatelessWidget {
  /// Id of the note to show.
  final String noteId;

  /// Tooltip of the delete button.
  final String deleteTooltip;

  /// Called with the note when it is tapped.
  final ValueChanged<Note> onTap;

  /// Called with the note id when the delete button is pressed.
  final ValueChanged<String> onDeletePressed;

  /// Creates the wrapper.
  const NoteTileWrapper({
    required this.noteId,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotesBloc, NotesState, Note?>(
      selector: _noteOf,
      builder: (BuildContext context, Note? note) => note == null
          ? const SizedBox.shrink()
          : NoteTileWidget(note: note, deleteTooltip: deleteTooltip, onTap: onTap, onDeletePressed: onDeletePressed),
    );
  }

  Note? _noteOf(NotesState state) => switch (state) {
    NotesLoaded(:final List<Note> notes) => notes.where(_isThis).firstOrNull,
    _ => null,
  };

  bool _isThis(Note note) => note.id == noteId;
}
