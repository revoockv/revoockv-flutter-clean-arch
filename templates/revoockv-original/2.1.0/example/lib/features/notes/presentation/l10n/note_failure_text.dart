import '../../domain/entities/note_failure.dart';

/// The text of a [NoteFailure] shown to the user.
extension NoteFailureText on NoteFailure {
  static const String _emptyText = 'Note text must not be empty';
  static const String _add = 'Could not add the note';
  static const String _update = 'Could not change the note';
  static const String _delete = 'Could not delete the note';
  static const String _load = 'Could not load the notes';

  /// The human-readable text of this failure.
  String get text => switch (this) {
        NoteFailure.emptyText => _emptyText,
        NoteFailure.add => _add,
        NoteFailure.update => _update,
        NoteFailure.delete => _delete,
        NoteFailure.load => _load,
      };
}
