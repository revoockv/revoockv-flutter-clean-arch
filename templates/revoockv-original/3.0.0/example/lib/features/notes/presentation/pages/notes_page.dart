import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note.dart';
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';
import 'package:example_app/features/pins/presentation/di/pins_getters.dart';
import 'package:example_app/features/pins/presentation/l10n/pin_failure_text.dart';
import 'package:example_app/features/pins/presentation/wrappers/pin_button_wrapper.dart';

import '../controllers/notes_controller.dart';
import '../di/notes_getters.dart';
import '../widgets/edit_note_dialog_widget.dart';
import '../wrappers/add_note_wrapper.dart';
import '../wrappers/notes_list_wrapper.dart';
import '../../domain/entities/note_failure.dart';
import '../l10n/note_failure_text.dart';

/// Notes tab: owns the [NotesController], calls the use cases, holds the texts and shows action errors as snackbars.
///
/// Never rebuilds itself — `registerHandler` only runs the handler; each wrapper below selects exactly what its
/// dumb widget shows.
final class NotesPage extends WatchingWidget {
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

  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesController notesController = createOnce(_createNotesController, dispose: _disposeNotesController);
    registerHandler(target: notesController.addingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.updatingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.deletingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.pinningStateController, handler: _onPinningChanged);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        children: <Widget>[
          AddNoteWrapper(
            noteTextController: notesController.noteTextController,
            addingState: notesController.addingStateController,
            hintText: _hintText,
            addLabel: _addLabel,
            onAddPressed: () => _onAddPressed(notesController),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Expanded(
            child: NotesListWrapper(
              emptyText: _emptyText,
              leadingBuilder: (String noteId) => PinButtonWrapper(
                noteId: noteId,
                pinTooltip: _pinTooltip,
                unpinTooltip: _unpinTooltip,
                onPressed: (String id) => _onPinPressed(notesController, id),
              ),
              deleteTooltip: _deleteTooltip,
              onNoteTap: (Note note) => _onEditPressed(context, notesController, note),
              onDeletePressed: (String id) => _onDeletePressed(notesController, id),
            ),
          ),
        ],
      ),
    );
  }

  static NotesController _createNotesController() => NotesController();

  static void _disposeNotesController(NotesController notesController) => notesController.dispose();

  void _onActionChanged(BuildContext context, ResultState<void, NoteFailure> state, void Function() cancel) {
    if (state is! FailureResultState<void, NoteFailure>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  void _onPinningChanged(BuildContext context, ResultState<void, PinFailure> state, void Function() cancel) {
    if (state is! FailureResultState<void, PinFailure>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  /// Adds the written note; ignored while one is being added. The field is
  /// cleared only after success, so a failed note keeps its text.
  Future<void> _onAddPressed(NotesController notesController) async {
    final ValueNotifier<ResultState<void, NoteFailure>> addingStateController = notesController.addingStateController;
    if (addingStateController.value.isLoading) return;
    addingStateController.value = ResultState.loading;

    final Result<void, NoteFailure> result = await addNoteUseCase(notesController.noteTextController.text);
    if (notesController.isDisposed) return;

    addingStateController.value = ResultState.of(result);
    if (result.isSuccess) notesController.noteTextController.clear();
  }

  /// Asks for the new text of [note] and saves it; nothing happens when the dialog is cancelled.
  Future<void> _onEditPressed(BuildContext context, NotesController notesController, Note note) async {
    final String? text = await EditNoteDialogWidget.show(context, initialText: note.text, texts: _editTexts);
    if (text == null || notesController.isDisposed) return;
    final ValueNotifier<ResultState<void, NoteFailure>> updatingStateController = notesController.updatingStateController;
    if (updatingStateController.value.isLoading) return;
    updatingStateController.value = ResultState.loading;

    final Result<void, NoteFailure> result = await updateNoteUseCase(note.id, text);
    if (notesController.isDisposed) return;

    updatingStateController.value = ResultState.of(result);
  }

  /// Deletes the note with [id]; ignored while another one is being deleted.
  Future<void> _onDeletePressed(NotesController notesController, String id) async {
    final ValueNotifier<ResultState<void, NoteFailure>> deletingStateController = notesController.deletingStateController;
    if (deletingStateController.value.isLoading) return;
    deletingStateController.value = ResultState.loading;

    final Result<void, NoteFailure> result = await deleteNoteUseCase(id);
    if (notesController.isDisposed) return;

    deletingStateController.value = ResultState.of(result);
  }

  /// Pins or unpins the note [noteId] with the pins feature's use case.
  Future<void> _onPinPressed(NotesController notesController, String noteId) async {
    final ValueNotifier<ResultState<void, PinFailure>> pinningStateController = notesController.pinningStateController;
    if (pinningStateController.value.isLoading) return;
    pinningStateController.value = ResultState.loading;

    final Result<void, PinFailure> result = await togglePinUseCase(noteId);
    if (notesController.isDisposed) return;

    pinningStateController.value = ResultState.of(result);
  }
}
