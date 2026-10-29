import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

/// Text field with an "Add" button. Owns nothing: the field's controller and the
/// action state come from the page's controller.
///
/// Only the button rebuilds when [actionState] changes.
final class AddNoteWidget extends StatelessWidget {
  /// Hint of the text field.
  static const String _hintText = 'New note';

  /// Text of the note being written.
  final TextEditingController textController;

  /// State of the running action; the button is disabled while it runs.
  final ValueListenable<ResultState<void>> actionState;

  /// Called when the user submits the note.
  final VoidCallback onSubmit;

  /// Creates the widget.
  const AddNoteWidget({
    required this.textController,
    required this.actionState,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: _hintText),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        _AddButtonWidget(actionState: actionState, onPressed: onSubmit),
      ],
    );
  }
}

/// The "Add" button — the only part that rebuilds when the action state changes.
final class _AddButtonWidget extends WatchingWidget {
  /// Label of the add button.
  static const String _addText = 'Add';

  final ValueListenable<ResultState<void>> actionState;

  final VoidCallback onPressed;

  const _AddButtonWidget({required this.actionState, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watch(actionState).value.isLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: const Text(_addText),
    );
  }
}
