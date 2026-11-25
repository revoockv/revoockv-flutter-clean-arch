import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/note_actions_cubit.dart';
import '../blocs/note_actions_state.dart';
import 'package:example_app/features/pins/presentation/blocs/pin_actions_cubit.dart';
import 'package:example_app/features/pins/presentation/blocs/pin_actions_state.dart';
import 'package:example_app/features/pins/presentation/l10n/pin_failure_text.dart';
import 'package:example_app/features/pins/presentation/wrappers/pin_button_wrapper.dart';

import '../../domain/entities/note.dart';
import '../widgets/edit_note_dialog_widget.dart';
import '../wrappers/add_note_wrapper.dart';
import '../wrappers/notes_list_wrapper.dart';
import '../l10n/note_failure_text.dart';

/// The notes tab below its blocs: holds the texts, passes the cubit's methods down as callbacks and shows action failures.
///
/// Never rebuilds itself — each wrapper below selects exactly what its dumb widget shows.
final class NotesView extends StatelessWidget {
  static const String _hintText = 'New note';
  static const String _addLabel = 'Add';
  static const String _emptyText = 'No notes yet';
  static const String _deleteTooltip = 'Delete';
  static const String _pinTooltip = 'Pin';
  static const String _unpinTooltip = 'Unpin';
  static const EditNoteDialogTexts _editTexts = EditNoteDialogTexts(
    titleText: 'Edit note',
    cancelLabel: 'Cancel',
    saveLabel: 'Save',
  );

  /// Creates the view.
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final NoteActionsCubit noteActionsCubit = context.read<NoteActionsCubit>();
    final PinActionsCubit pinActionsCubit = context.read<PinActionsCubit>();
    return BlocListener<NoteActionsCubit, NoteActionsState>(
      listenWhen: _isFailure,
      listener: _onActionFailed,
      child: BlocListener<PinActionsCubit, PinActionsState>(
        listenWhen: _isPinFailure,
        listener: _onPinFailed,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            children: <Widget>[
              AddNoteWrapper(hintText: _hintText, addLabel: _addLabel, onAddPressed: noteActionsCubit.add),
              const SizedBox(height: AppTheme.spacingMedium),
              Expanded(
                child: NotesListWrapper(
                  emptyText: _emptyText,
                  leadingBuilder: (String noteId) => PinButtonWrapper(
                    noteId: noteId,
                    pinTooltip: _pinTooltip,
                    unpinTooltip: _unpinTooltip,
                    onPressed: pinActionsCubit.toggle,
                  ),
                  deleteTooltip: _deleteTooltip,
                  onNoteTap: (Note note) => _onEditPressed(context, note),
                  onDeletePressed: noteActionsCubit.delete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isFailure(NoteActionsState previous, NoteActionsState current) => current is NoteActionsFailed;

  static void _onActionFailed(BuildContext context, NoteActionsState state) {
    if (state is! NoteActionsFailed) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  static bool _isPinFailure(PinActionsState previous, PinActionsState current) => current is PinActionsFailed;

  static void _onPinFailed(BuildContext context, PinActionsState state) {
    if (state is! PinActionsFailed) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  /// Asks for the new text of [note] and saves it; nothing happens when the dialog is cancelled.
  Future<void> _onEditPressed(BuildContext context, Note note) async {
    final String? text = await EditNoteDialogWidget.show(context, initialText: note.text, texts: _editTexts);
    if (text == null || !context.mounted) return;
    await context.read<NoteActionsCubit>().update(note.id, text);
  }
}
