import 'package:example_app/core/domain/entities/result.dart';

import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import '../entities/note_failure.dart';

/// Watch use case: the live list of notes.
final class WatchNotesUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  WatchNotesUseCase(this._repository);

  /// The notes right away, then after every change (or the load failure).
  Stream<Result<List<Note>, NoteFailure>> call() => _repository.watchNotes();
}
