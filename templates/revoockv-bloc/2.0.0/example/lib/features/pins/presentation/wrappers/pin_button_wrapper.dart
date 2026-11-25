import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/pins_bloc.dart';
import '../blocs/pins_state.dart';
import '../widgets/pin_button_widget.dart';

/// Gives [PinButtonWidget] whether its note is pinned: rebuilds only when this note is pinned or unpinned.
///
/// Other features place it (the notes list puts one into every note) under a [PinsBloc].
final class PinButtonWrapper extends StatelessWidget {
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
    return BlocSelector<PinsBloc, PinsState, bool>(
      selector: _isPinnedOf,
      builder: (BuildContext context, bool isPinned) => PinButtonWidget(
        isPinned: isPinned,
        pinTooltip: pinTooltip,
        unpinTooltip: unpinTooltip,
        onPressed: _onPressed,
      ),
    );
  }

  bool _isPinnedOf(PinsState state) => state.isPinned(noteId);

  void _onPressed() {
    onPressed(noteId);
  }
}
