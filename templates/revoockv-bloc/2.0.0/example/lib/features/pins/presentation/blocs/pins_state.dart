import '../../domain/entities/pin_failure.dart';
import '../../domain/entities/pinned_notes.dart';

/// The pinned notes as the screen shows them.
sealed class PinsState {
  const PinsState();

  /// Whether the note [noteId] is pinned; `false` until the pins are loaded.
  bool isPinned(String noteId) => false;
}

/// The first pins have not arrived yet.
final class PinsLoading extends PinsState {
  /// Creates the state.
  const PinsLoading();
}

/// The stored pins.
final class PinsLoaded extends PinsState {
  /// The pins.
  final PinnedNotes pins;

  /// Creates the state.
  const PinsLoaded(this.pins);

  @override
  bool isPinned(String noteId) => pins.contains(noteId);

  @override
  bool operator ==(Object other) => other is PinsLoaded && other.pins == pins;

  @override
  int get hashCode => pins.hashCode;
}

/// The pins could not be loaded.
final class PinsLoadFailed extends PinsState {
  /// What went wrong.
  final PinFailure failure;

  /// Creates the state.
  const PinsLoadFailed(this.failure);

  @override
  bool operator ==(Object other) => other is PinsLoadFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
