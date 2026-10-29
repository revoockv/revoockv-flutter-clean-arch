import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../controllers/notes_controller.dart';
import '../di/notes_getters.dart';
import '../widgets/add_note_widget.dart';
import '../widgets/notes_list_widget.dart';

/// Notes screen: owns the [NotesController] and shows action errors as snackbars.
///
/// Never rebuilds itself — `registerHandler` only runs the handler; the widgets below
/// watch exactly what they show.
final class NotesPage extends WatchingWidget {
  /// Title of the app bar.
  static const String _title = 'Notes';

  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesController controller = createOnce(_createController, dispose: _disposeController);
    registerHandler(target: controller, handler: _onActionChanged);

    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: <Widget>[
            AddNoteWidget(textController: controller.text, actionState: controller, onSubmit: controller.addNote),
            const SizedBox(height: AppTheme.spacingMedium),
            Expanded(child: NotesListWidget(onDelete: controller.deleteNote)),
          ],
        ),
      ),
    );
  }

  static NotesController _createController() =>
      NotesController(add: addNoteUseCase.call, delete: deleteNoteUseCase.call);

  static void _disposeController(NotesController controller) => controller.dispose();

  void _onActionChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    if (state is! FailureResultState<void>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
  }
}
