import 'package:flutter/material.dart';

/// A pin button: filled while the note is pinned.
///
/// Dumb: the flag, the tooltips and the callback come from above.
final class PinButtonWidget extends StatelessWidget {
  /// Whether the note is pinned.
  final bool isPinned;

  /// Tooltip while the note is not pinned.
  final String pinTooltip;

  /// Tooltip while the note is pinned.
  final String unpinTooltip;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates the button.
  const PinButtonWidget({
    required this.isPinned,
    required this.pinTooltip,
    required this.unpinTooltip,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
      tooltip: isPinned ? unpinTooltip : pinTooltip,
      onPressed: onPressed,
    );
  }
}
