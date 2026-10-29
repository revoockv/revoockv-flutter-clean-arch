import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

/// UI logic of the notes page: the text of a new note and one [ResultState]
/// for adding and deleting notes.
///
/// Knows nothing about DI or use cases — the owner passes the actions in, like callbacks.
final class NotesController extends ValueNotifier<ResultState<void>> {
  /// Text of the note being written; cleared only after it was added.
  final TextEditingController text = TextEditingController();

  final Future<Result<void>> Function(String text) _add;

  final Future<Result<void>> Function(String id) _delete;

  bool _isDisposed = false;

  /// Creates the controller with the actions it runs.
  NotesController({required this._add, required this._delete}) : super(ResultState.idle);

  /// Adds a note with the entered [text]; clears the field on success, keeps it on failure.
  Future<void> addNote() async {
    final bool isAdded = await _run(() => _add(text.text));
    if (isAdded) text.clear();
  }

  /// Deletes the note with [id]; ignored while another action runs.
  Future<void> deleteNote(String id) => _run(() => _delete(id));

  /// Releases the text controller and the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  @override
  void dispose() {
    _isDisposed = true;
    text.dispose();
    super.dispose();
  }

  /// Runs [action] unless another one is running, records its outcome and
  /// returns whether it succeeded.
  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (value.isLoading) return false;
    value = ResultState.loading;

    final Result<void> result = await action();
    if (_isDisposed) return false;

    value = ResultState.of(result);
    return result.isSuccess;
  }
}
