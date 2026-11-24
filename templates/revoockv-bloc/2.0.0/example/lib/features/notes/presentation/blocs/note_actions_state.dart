import '../../domain/entities/note_failure.dart';

/// An action on notes.
enum NoteAction {
  /// A note was added.
  added,

  /// A note was changed.
  updated,

  /// A note was deleted.
  deleted,
}

/// Progress of the last action on notes (add, delete).
sealed class NoteActionsState {
  const NoteActionsState();

  /// Whether an action runs now.
  bool get isRunning => this is NoteActionsRunning;
}

/// No action has run yet.
final class NoteActionsIdle extends NoteActionsState {
  /// Creates the state.
  const NoteActionsIdle();
}

/// An action runs.
final class NoteActionsRunning extends NoteActionsState {
  /// Creates the state.
  const NoteActionsRunning();
}

/// The last action succeeded.
final class NoteActionsDone extends NoteActionsState {
  /// Which action it was.
  final NoteAction action;

  /// Creates the state.
  const NoteActionsDone(this.action);

  @override
  bool operator ==(Object other) => other is NoteActionsDone && other.action == action;

  @override
  int get hashCode => action.hashCode;
}

/// The last action failed.
final class NoteActionsFailed extends NoteActionsState {
  /// What went wrong; the page turns it into text.
  final NoteFailure failure;

  /// Creates the state.
  const NoteActionsFailed(this.failure);

  @override
  bool operator ==(Object other) => other is NoteActionsFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
