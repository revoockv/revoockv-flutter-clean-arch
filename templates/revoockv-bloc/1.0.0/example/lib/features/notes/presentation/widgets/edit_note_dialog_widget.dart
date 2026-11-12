import 'package:flutter/material.dart';

/// "Edit note" dialog: a field with the note's text, Cancel and Save. Returns the new text, or `null` when cancelled.
///
/// Owns its field's controller; knows no blocs — the caller saves the text.
final class EditNoteDialogWidget extends StatefulWidget {
  /// The text the field starts with.
  final String initialText;

  /// Creates the dialog.
  const EditNoteDialogWidget({required this.initialText, super.key});

  /// Shows the dialog over [context] with [initialText]; completes with the new text or `null`.
  static Future<String?> show(BuildContext context, String initialText) =>
      showDialog<String>(context: context, builder: (BuildContext context) => EditNoteDialogWidget(initialText: initialText));

  @override
  State<EditNoteDialogWidget> createState() => _EditNoteDialogWidgetState();
}

final class _EditNoteDialogWidgetState extends State<EditNoteDialogWidget> {
  /// Title of the dialog.
  static const String _title = 'Edit note';

  /// Label of the cancel button.
  static const String _cancelText = 'Cancel';

  /// Label of the save button.
  static const String _saveText = 'Save';

  late final TextEditingController _noteTextController;

  @override
  void initState() {
    super.initState();
    _noteTextController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(_title),
      content: TextField(controller: _noteTextController, autofocus: true),
      actions: <Widget>[
        TextButton(onPressed: _onCancelPressed, child: const Text(_cancelText)),
        TextButton(onPressed: _onSavePressed, child: const Text(_saveText)),
      ],
    );
  }

  void _onCancelPressed() {
    Navigator.of(context).pop();
  }

  void _onSavePressed() {
    Navigator.of(context).pop(_noteTextController.text);
  }
}
