import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note_failure.dart';
import '../widgets/add_note_widget.dart';

/// Gives [AddNoteWidget] whether a note is being added: rebuilds only when adding starts or ends.
final class AddNoteWrapper extends WatchingWidget {
  /// Text of the note being written.
  final TextEditingController noteTextController;

  /// Progress of adding, kept by the page's controller.
  final ValueListenable<ResultState<void, NoteFailure>> addingState;

  /// Hint of the empty field.
  final String hintText;

  /// Label of the add button.
  final String addLabel;

  /// Called when the add button is pressed; the page adds the note.
  final VoidCallback onAddPressed;

  /// Creates the wrapper.
  const AddNoteWrapper({
    required this.noteTextController,
    required this.addingState,
    required this.hintText,
    required this.addLabel,
    required this.onAddPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdding = watchPropertyValue(_isAddingOf, target: addingState);
    return AddNoteWidget(
      noteTextController: noteTextController,
      isAdding: isAdding,
      hintText: hintText,
      addLabel: addLabel,
      onAddPressed: onAddPressed,
    );
  }

  static bool _isAddingOf(ValueListenable<ResultState<void, NoteFailure>> state) => state.value.isLoading;
}
