import 'package:example_app/core/domain/entities/result.dart';

import '../entities/note.dart';
import '../repositories/notes_repository.dart';

/// Watch use case: the live list of notes.
final class WatchNotesUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  WatchNotesUseCase(this._repository);

  /// The notes right away, then after every change (or the load failure).
  Stream<Result<List<Note>>> call() => _repository.watchNotes();
}
