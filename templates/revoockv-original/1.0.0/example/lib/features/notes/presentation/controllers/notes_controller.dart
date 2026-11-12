import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

/// UI state of the notes page, like a Flutter controller: the text of a new note
/// and the progress of adding and deleting notes.
///
/// Knows nothing about use cases: the page calls them and records the outcome here.
final class NotesController {
  /// Text of the note being written; the page clears it only after the note was added.
  final TextEditingController noteTextController = TextEditingController();

  /// Progress of adding a note; the add button is disabled while it runs.
  final ValueNotifier<ResultState<void>> addingStateController = ValueNotifier<ResultState<void>>(ResultState.idle);

  /// Progress of deleting a note.
  final ValueNotifier<ResultState<void>> deletingStateController = ValueNotifier<ResultState<void>>(ResultState.idle);

  bool _isDisposed = false;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Releases the controllers. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    noteTextController.dispose();
    addingStateController.dispose();
    deletingStateController.dispose();
  }
}
