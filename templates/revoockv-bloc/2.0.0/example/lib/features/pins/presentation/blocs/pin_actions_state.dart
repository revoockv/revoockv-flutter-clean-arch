import '../../domain/entities/pin_failure.dart';

/// Progress of the last pin or unpin.
sealed class PinActionsState {
  const PinActionsState();

  /// Whether a pin or unpin runs now.
  bool get isRunning => this is PinActionsRunning;
}

/// Nothing ran yet, or the last one succeeded.
final class PinActionsIdle extends PinActionsState {
  /// Creates the state.
  const PinActionsIdle();
}

/// A pin or unpin runs.
final class PinActionsRunning extends PinActionsState {
  /// Creates the state.
  const PinActionsRunning();
}

/// The last pin or unpin failed.
final class PinActionsFailed extends PinActionsState {
  /// What went wrong; the page turns it into text.
  final PinFailure failure;

  /// Creates the state.
  const PinActionsFailed(this.failure);

  @override
  bool operator ==(Object other) => other is PinActionsFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
