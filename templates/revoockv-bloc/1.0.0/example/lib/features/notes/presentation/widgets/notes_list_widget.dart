import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/note.dart';
import '../blocs/note_actions_cubit.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_state.dart';
import 'edit_note_dialog_widget.dart';
import 'note_tile_widget.dart';

/// Live list of notes: a progress indicator while loading, the load error, or the notes.
/// Editing and deleting go to [NoteActionsCubit].
final class NotesListWidget extends StatelessWidget {
  /// Text shown when there are no notes.
  static const String _emptyText = 'No notes yet';

  /// Creates the list.
  const NotesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesState notes = context.watch<NotesBloc>().state;
    return switch (notes) {
      NotesLoading() => const Center(child: CircularProgressIndicator()),
      NotesLoadFailed(:final String message) => Center(child: Text(message)),
      NotesLoaded(:final List<Note> notes) when notes.isEmpty => const Center(child: Text(_emptyText)),
      NotesLoaded(:final List<Note> notes) => ListView(
          children: <Widget>[
            for (final Note note in notes)
              NoteTileWidget(
                note: note,
                onEdit: (Note note) => _onEditPressed(context, note),
                onDelete: context.read<NoteActionsCubit>().delete,
              ),
          ],
        ),
    };
  }

  /// Asks for the new text of [note] and saves it; nothing happens when the dialog is cancelled.
  Future<void> _onEditPressed(BuildContext context, Note note) async {
    final String? text = await EditNoteDialogWidget.show(context, note.text);
    if (text == null || !context.mounted) return;
    await context.read<NoteActionsCubit>().update(note.id, text);
  }
}
