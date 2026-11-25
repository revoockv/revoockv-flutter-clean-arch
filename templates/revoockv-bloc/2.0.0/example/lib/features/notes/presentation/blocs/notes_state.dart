import 'package:flutter/foundation.dart' show listEquals;

import '../../domain/entities/note.dart';
import '../../domain/entities/note_failure.dart';

/// What the notes list shows.
sealed class NotesState {
  const NotesState();
}

/// The first notes have not arrived yet.
final class NotesLoading extends NotesState {
  /// Creates the state.
  const NotesLoading();
}

/// The stored notes.
final class NotesLoaded extends NotesState {
  /// The notes, in the order they were added.
  final List<Note> notes;

  /// Creates the state.
  const NotesLoaded(this.notes);

  @override
  bool operator ==(Object other) => other is NotesLoaded && listEquals(other.notes, notes);

  @override
  int get hashCode => Object.hashAll(notes);
}

/// The notes could not be loaded.
final class NotesLoadFailed extends NotesState {
  /// What went wrong; the list turns it into text.
  final NoteFailure failure;

  /// Creates the state.
  const NotesLoadFailed(this.failure);

  @override
  bool operator ==(Object other) => other is NotesLoadFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
