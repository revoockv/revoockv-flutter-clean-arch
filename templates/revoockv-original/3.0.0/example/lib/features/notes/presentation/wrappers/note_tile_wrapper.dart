import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_failure.dart';
import '../di/notes_getters.dart';
import '../widgets/note_tile_widget.dart';

/// Gives [NoteTileWidget] its note: rebuilds only when this note changes, not when another one does.
final class NoteTileWrapper extends WatchingWidget {
  /// Id of the note to show.
  final String noteId;

  /// Tooltip of the delete button.
  final String deleteTooltip;

  /// Called with the note when it is tapped.
  final ValueChanged<Note> onTap;

  /// Called with the note id when the delete button is pressed.
  final ValueChanged<String> onDeletePressed;

  /// Creates the wrapper.
  const NoteTileWrapper({
    required this.noteId,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Note? note = watchPropertyValue(_noteOf, target: watchNotesUseCase());
    if (note == null) return const SizedBox.shrink();
    return NoteTileWidget(
      note: note,
      deleteTooltip: deleteTooltip,
      onTap: onTap,
      onDeletePressed: onDeletePressed,
    );
  }

  Note? _noteOf(ValueListenable<ResultState<List<Note>, NoteFailure>> notes) => switch (notes.value) {
    SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) => value.where(_isThis).firstOrNull,
    _ => null,
  };

  bool _isThis(Note note) => note.id == noteId;
}
