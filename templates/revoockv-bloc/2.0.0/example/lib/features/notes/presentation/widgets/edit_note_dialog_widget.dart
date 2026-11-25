import 'package:flutter/material.dart';

/// The texts of [EditNoteDialogWidget].
final class EditNoteDialogTexts {
  /// Title of the dialog.
  final String titleText;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Label of the save button.
  final String saveLabel;

  /// Creates the texts.
  const EditNoteDialogTexts({required this.titleText, required this.cancelLabel, required this.saveLabel});
}

/// A dialog with the note's text, Cancel and Save; returns the new text, or `null` when cancelled.
///
/// Dumb: it owns only its field's controller (plain Flutter) and knows no use cases — whoever shows it saves the text.
final class EditNoteDialogWidget extends StatefulWidget {
  /// The text the field starts with.
  final String initialText;

  /// The title and the button labels.
  final EditNoteDialogTexts texts;

  /// Creates the dialog.
  const EditNoteDialogWidget({required this.initialText, required this.texts, super.key});

  /// Shows the dialog over [context]; completes with the new text or `null`.
  static Future<String?> show(
    BuildContext context, {
    required String initialText,
    required EditNoteDialogTexts texts,
  }) => showDialog<String>(
    context: context,
    builder: (BuildContext context) => EditNoteDialogWidget(initialText: initialText, texts: texts),
  );

  @override
  State<EditNoteDialogWidget> createState() => _EditNoteDialogWidgetState();
}

final class _EditNoteDialogWidgetState extends State<EditNoteDialogWidget> {
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
      title: Text(widget.texts.titleText),
      content: TextField(controller: _noteTextController, autofocus: true),
      actions: <Widget>[
        TextButton(onPressed: _onCancelPressed, child: Text(widget.texts.cancelLabel)),
        TextButton(onPressed: _onSavePressed, child: Text(widget.texts.saveLabel)),
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
