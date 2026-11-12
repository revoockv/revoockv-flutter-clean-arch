import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

/// Text field with an "Add" button. Owns nothing and knows no use cases: the
/// field's controller and the adding state come from the page.
///
/// Only the button rebuilds when [addingState] changes.
final class AddNoteWidget extends StatelessWidget {
  /// Hint of the text field.
  static const String _hintText = 'New note';

  /// Text of the note being written.
  final TextEditingController textController;

  /// Progress of adding; the button is disabled while it runs.
  final ValueListenable<ResultState<void>> addingState;

  /// Called when the user submits the note.
  final VoidCallback onSubmit;

  /// Creates the widget.
  const AddNoteWidget({
    required this.textController,
    required this.addingState,
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
        _AddButtonWidget(addingState: addingState, onPressed: onSubmit),
      ],
    );
  }
}

/// The "Add" button — the only part that rebuilds when the adding state changes.
final class _AddButtonWidget extends WatchingWidget {
  /// Label of the add button.
  static const String _addText = 'Add';

  final ValueListenable<ResultState<void>> addingState;

  final VoidCallback onPressed;

  const _AddButtonWidget({required this.addingState, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watch(addingState).value.isLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: const Text(_addText),
    );
  }
}
