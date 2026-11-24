/// What the pins are asked to do.
sealed class PinsEvent {
  const PinsEvent();
}

/// The pins start following the stored pins.
final class PinsSubscribed extends PinsEvent {
  /// Creates the event.
  const PinsSubscribed();
}
