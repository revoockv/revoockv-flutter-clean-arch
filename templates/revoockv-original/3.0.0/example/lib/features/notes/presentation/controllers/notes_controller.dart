import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';

import '../../domain/entities/note_failure.dart';

/// UI state of the notes page, like a Flutter controller: the text of a new note
/// and the progress of adding, changing and deleting notes.
///
/// Knows nothing about use cases: the page calls them and records the outcome here.
final class NotesController {
  /// Text of the note being written; the page clears it only after the note was added.
  final TextEditingController noteTextController = TextEditingController();

  /// Progress of adding a note; the add button is disabled while it runs.
  final ValueNotifier<ResultState<void, NoteFailure>> addingStateController = ValueNotifier<ResultState<void, NoteFailure>>(ResultState.idle);

  /// Progress of changing a note.
  final ValueNotifier<ResultState<void, NoteFailure>> updatingStateController = ValueNotifier<ResultState<void, NoteFailure>>(ResultState.idle);

  /// Progress of pinning or unpinning a note (the pins feature's action).
  final ValueNotifier<ResultState<void, PinFailure>> pinningStateController = ValueNotifier<ResultState<void, PinFailure>>(ResultState.idle);

  /// Progress of deleting a note.
  final ValueNotifier<ResultState<void, NoteFailure>> deletingStateController = ValueNotifier<ResultState<void, NoteFailure>>(ResultState.idle);

  bool _isDisposed = false;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Releases the controllers. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    noteTextController.dispose();
    addingStateController.dispose();
    updatingStateController.dispose();
    deletingStateController.dispose();
    pinningStateController.dispose();
  }
}
