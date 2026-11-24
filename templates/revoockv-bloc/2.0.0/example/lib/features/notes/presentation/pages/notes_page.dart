import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/update_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';
import '../blocs/note_actions_cubit.dart';
import '../blocs/note_actions_state.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_event.dart';
import '../../domain/entities/note.dart';
import '../widgets/edit_note_dialog_widget.dart';
import '../wrappers/add_note_wrapper.dart';
import '../wrappers/notes_list_wrapper.dart';
import '../l10n/note_failure_text.dart';

/// Notes tab: creates its blocs from the feature's use cases and shows action errors as snackbars.
final class NotesPage extends StatelessWidget {
  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: const [
        BlocProvider<NotesBloc>(create: _createNotesBloc),
        BlocProvider<NoteActionsCubit>(create: _createNoteActionsCubit),
      ],
      child: const _NotesViewWidget(),
    );
  }

  static NotesBloc _createNotesBloc(BuildContext context) =>
      NotesBloc(watchNotesUseCase: context.read<WatchNotesUseCase>())..add(const NotesSubscribed());

  static NoteActionsCubit _createNoteActionsCubit(BuildContext context) => NoteActionsCubit(
        addNoteUseCase: context.read<AddNoteUseCase>(),
        updateNoteUseCase: context.read<UpdateNoteUseCase>(),
        deleteNoteUseCase: context.read<DeleteNoteUseCase>(),
      );
}

/// The tab below the blocs: holds the texts, passes the cubit's methods down as callbacks and shows action failures.
///
/// Never rebuilds itself — each wrapper below selects exactly what its dumb widget shows.
final class _NotesViewWidget extends StatelessWidget {
  static const String _hintText = 'New note';
  static const String _addLabel = 'Add';
  static const String _emptyText = 'No notes yet';
  static const String _deleteTooltip = 'Delete';
  static const EditNoteDialogTexts _editTexts = EditNoteDialogTexts(
    titleText: 'Edit note',
    cancelLabel: 'Cancel',
    saveLabel: 'Save',
  );

  const _NotesViewWidget();

  @override
  Widget build(BuildContext context) {
    final NoteActionsCubit noteActionsCubit = context.read<NoteActionsCubit>();
    return BlocListener<NoteActionsCubit, NoteActionsState>(
      listenWhen: _isFailure,
      listener: _onActionFailed,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: <Widget>[
            AddNoteWrapper(hintText: _hintText, addLabel: _addLabel, onAddPressed: noteActionsCubit.add),
            const SizedBox(height: AppTheme.spacingMedium),
            Expanded(
              child: NotesListWrapper(
                emptyText: _emptyText,
                deleteTooltip: _deleteTooltip,
                onNoteTap: (Note note) => _onEditPressed(context, note),
                onDeletePressed: noteActionsCubit.delete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isFailure(NoteActionsState previous, NoteActionsState current) => current is NoteActionsFailed;

  static void _onActionFailed(BuildContext context, NoteActionsState state) {
    if (state is! NoteActionsFailed) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  /// Asks for the new text of [note] and saves it; nothing happens when the dialog is cancelled.
  Future<void> _onEditPressed(BuildContext context, Note note) async {
    final String? text = await EditNoteDialogWidget.show(context, initialText: note.text, texts: _editTexts);
    if (text == null || !context.mounted) return;
    await context.read<NoteActionsCubit>().update(note.id, text);
  }
}
