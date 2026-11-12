import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

/// "Edit note" dialog: a field with the note's text, Cancel and Save. Returns the new text, or `null` when cancelled.
///
/// Owns its field's controller with `createOnce`; knows no use cases — the page saves the text.
final class EditNoteDialogWidget extends WatchingWidget {
  /// Title of the dialog.
  static const String _title = 'Edit note';

  /// Label of the cancel button.
  static const String _cancelText = 'Cancel';

  /// Label of the save button.
  static const String _saveText = 'Save';

  /// The text the field starts with.
  final String initialText;

  /// Creates the dialog.
  const EditNoteDialogWidget({required this.initialText, super.key});

  /// Shows the dialog over [context] with [initialText]; completes with the new text or `null`.
  static Future<String?> show(BuildContext context, String initialText) =>
      showDialog<String>(context: context, builder: (BuildContext context) => EditNoteDialogWidget(initialText: initialText));

  @override
  Widget build(BuildContext context) {
    final TextEditingController noteTextController = createOnce(_createNoteTextController, dispose: _disposeNoteTextController);
    return AlertDialog(
      title: const Text(_title),
      content: TextField(controller: noteTextController, autofocus: true),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: const Text(_cancelText)),
        TextButton(onPressed: () => _onSavePressed(context, noteTextController), child: const Text(_saveText)),
      ],
    );
  }

  TextEditingController _createNoteTextController() => TextEditingController(text: initialText);

  static void _disposeNoteTextController(TextEditingController noteTextController) => noteTextController.dispose();

  void _onCancelPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onSavePressed(BuildContext context, TextEditingController noteTextController) {
    Navigator.of(context).pop(noteTextController.text);
  }
}
