/// What the notes list is asked to do.
sealed class NotesEvent {
  const NotesEvent();
}

/// The list starts following the stored notes.
final class NotesSubscribed extends NotesEvent {
  /// Creates the event.
  const NotesSubscribed();
}
