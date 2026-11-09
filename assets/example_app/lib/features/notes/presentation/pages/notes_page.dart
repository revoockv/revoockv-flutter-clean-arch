import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:example_app/features/api_server/presentation/pages/api_server_page.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../controllers/notes_controller.dart';
import '../di/notes_getters.dart';
import '../widgets/add_note_widget.dart';
import '../widgets/notes_list_widget.dart';

/// Notes screen: owns the [NotesController], calls the use cases and shows
/// action errors as snackbars.
///
/// Never rebuilds itself — `registerHandler` only runs the handler; the widgets below
/// watch exactly what they show.
final class NotesPage extends WatchingWidget {
  /// Title of the app bar.
  static const String _title = 'Notes';

  /// Tooltip of the button that opens the API server settings.
  static const String _apiServerTooltip = 'API server';

  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesController notesController = createOnce(_createNotesController, dispose: _disposeNotesController);
    registerHandler(target: notesController.addingStateController, handler: _onActionChanged);
    registerHandler(target: notesController.deletingStateController, handler: _onActionChanged);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            tooltip: _apiServerTooltip,
            onPressed: () => _openApiServer(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: <Widget>[
            AddNoteWidget(
              textController: notesController.noteTextController,
              addingState: notesController.addingStateController,
              onSubmit: () => _onAddPressed(notesController),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Expanded(child: NotesListWidget(onDelete: (String id) => _onDeletePressed(notesController, id))),
          ],
        ),
      ),
    );
  }

  static NotesController _createNotesController() => NotesController();

  static void _disposeNotesController(NotesController notesController) => notesController.dispose();

  void _openApiServer(BuildContext context) {
    ApiServerPage.show(context);
  }

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
