import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// One note with a delete button. Knows nothing about use cases.
final class NoteTileWidget extends StatelessWidget {
  /// Tooltip of the delete button.
  static const String _deleteTooltip = 'Delete';

  /// The note to show.
  final Note note;

  /// Called with the note id when the delete button is pressed.
  final ValueChanged<String> onDelete;

  /// Creates the tile.
  const NoteTileWidget({required this.note, required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.text),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: _deleteTooltip,
        onPressed: _onDeletePressed,
      ),
    );
  }

  void _onDeletePressed() {
    onDelete(note.id);
  }
}
