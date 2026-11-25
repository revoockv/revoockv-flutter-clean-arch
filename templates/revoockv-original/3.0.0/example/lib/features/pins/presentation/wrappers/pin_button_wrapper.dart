import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/pin_failure.dart';
import '../../domain/entities/pinned_notes.dart';
import '../di/pins_getters.dart';
import '../widgets/pin_button_widget.dart';

/// Gives [PinButtonWidget] whether its note is pinned: rebuilds only when this note is pinned or unpinned.
///
/// Other features place it (the notes list puts one into every note).
final class PinButtonWrapper extends WatchingWidget {
  /// Id of the note.
  final String noteId;

  /// Tooltip while the note is not pinned.
  final String pinTooltip;

  /// Tooltip while the note is pinned.
  final String unpinTooltip;

  /// Called with the note id when the button is pressed; the page pins or unpins it.
  final ValueChanged<String> onPressed;

  /// Creates the wrapper.
  const PinButtonWrapper({
    required this.noteId,
    required this.pinTooltip,
    required this.unpinTooltip,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPinned = watchPropertyValue(_isPinnedOf, target: watchPinnedNotesUseCase());
    return PinButtonWidget(
      isPinned: isPinned,
      pinTooltip: pinTooltip,
      unpinTooltip: unpinTooltip,
      onPressed: _onPressed,
    );
  }

  bool _isPinnedOf(ValueListenable<ResultState<PinnedNotes, PinFailure>> pins) => switch (pins.value) {
    SuccessResultState<PinnedNotes, PinFailure>(:final PinnedNotes value) => value.contains(noteId),
    _ => false,
  };

  void _onPressed() {
    onPressed(noteId);
  }
}
