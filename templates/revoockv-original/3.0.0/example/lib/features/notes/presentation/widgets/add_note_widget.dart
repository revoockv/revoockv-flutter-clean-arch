import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';

/// A text field with an add button; the button is off while a note is being added.
///
/// Dumb: the field's controller, the texts and the callback come from above.
final class AddNoteWidget extends StatelessWidget {
  /// Text of the note being written.
  final TextEditingController noteTextController;

  /// Whether a note is being added; the button is off meanwhile.
  final bool isAdding;

  /// Hint of the empty field.
  final String hintText;

  /// Label of the add button.
  final String addLabel;

  /// Called when the add button is pressed.
  final VoidCallback onAddPressed;

  /// Creates the widget.
  const AddNoteWidget({
    required this.noteTextController,
    required this.isAdding,
    required this.hintText,
    required this.addLabel,
    required this.onAddPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: noteTextController,
            decoration: InputDecoration(hintText: hintText),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        ElevatedButton(onPressed: isAdding ? null : onAddPressed, child: Text(addLabel)),
      ],
    );
  }
}
