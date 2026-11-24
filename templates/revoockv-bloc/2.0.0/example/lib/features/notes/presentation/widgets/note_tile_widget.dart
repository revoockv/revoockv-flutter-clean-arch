import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// One note: tap it to edit it, a button deletes it.
///
/// Dumb: the note, the tooltip and the callbacks come from above.
final class NoteTileWidget extends StatelessWidget {
  /// The note to show.
  final Note note;

  /// Tooltip of the delete button.
  final String deleteTooltip;

  /// Called with the note when it is tapped.
  final ValueChanged<Note> onTap;

  /// Called with the note id when the delete button is pressed.
  final ValueChanged<String> onDeletePressed;

  /// Creates the tile.
  const NoteTileWidget({
    required this.note,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.text),
      onTap: _onTap,
      trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: deleteTooltip, onPressed: _onDeletePressed),
    );
  }

  void _onTap() {
    onTap(note);
  }

  void _onDeletePressed() {
    onDeletePressed(note.id);
  }
}
