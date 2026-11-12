import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note.dart';
import '../controllers/notes_controller.dart';
import '../di/notes_getters.dart';
import '../widgets/add_note_widget.dart';
import '../widgets/edit_note_dialog_widget.dart';
import '../widgets/notes_list_widget.dart';

/// Notes tab: owns the [NotesController], calls the use cases and shows
/// action errors as snackbars.
///
/// Never rebuilds itself — `registerHandler` only runs the handler; the widgets below
/// watch exactly what they show.
final class NotesPage extends WatchingWidget {
  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesController notesController = createOnce(_createNotesController, dispose: _disposeNotesController);
    registerHandler(target: notesController.addingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.updatingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.deletingStateController, handler: _onActionChanged);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        children: <Widget>[
          AddNoteWidget(
            textController: notesController.noteTextController,
            addingState: notesController.addingStateController,
            onSubmit: () => _onAddPressed(notesController),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Expanded(
            child: NotesListWidget(
              onEdit: (Note note) => _onEditPressed(context, notesController, note),
              onDelete: (String id) => _onDeletePressed(notesController, id),
            ),
          ),
        ],
      ),
    );
  }

  static NotesController _createNotesController() => NotesController();

  static void _disposeNotesController(NotesController notesController) => notesController.dispose();

  void _onActionChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    if (state is! FailureResultState<void>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
  }

  /// Adds the written note; ignored while one is being added. The field is
  /// cleared only after success, so a failed note keeps its text.
  Future<void> _onAddPressed(NotesController notesController) async {
    final ValueNotifier<ResultState<void>> addingStateController = notesController.addingStateController;
    if (addingStateController.value.isLoading) return;
    addingStateController.value = ResultState.loading;

    final Result<void> result = await addNoteUseCase(notesController.noteTextController.text);
    if (notesController.isDisposed) return;

    addingStateController.value = ResultState.of(result);
    if (result.isSuccess) notesController.noteTextController.clear();
  }

  /// Asks for the new text of [note] and saves it; nothing happens when the dialog is cancelled.
  Future<void> _onEditPressed(BuildContext context, NotesController notesController, Note note) async {
    final String? text = await EditNoteDialogWidget.show(context, note.text);
    if (text == null || notesController.isDisposed) return;
    final ValueNotifier<ResultState<void>> updatingStateController = notesController.updatingStateController;
    if (updatingStateController.value.isLoading) return;
    updatingStateController.value = ResultState.loading;

    final Result<void> result = await updateNoteUseCase(note.id, text);
    if (notesController.isDisposed) return;

    updatingStateController.value = ResultState.of(result);
  }

  /// Deletes the note with [id]; ignored while another one is being deleted.
  Future<void> _onDeletePressed(NotesController notesController, String id) async {
    final ValueNotifier<ResultState<void>> deletingStateController = notesController.deletingStateController;
    if (deletingStateController.value.isLoading) return;
    deletingStateController.value = ResultState.loading;

    final Result<void> result = await deleteNoteUseCase(id);
    if (notesController.isDisposed) return;

    deletingStateController.value = ResultState.of(result);
  }
}
