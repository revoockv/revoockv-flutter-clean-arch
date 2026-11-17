import 'package:example_app/core/domain/entities/result.dart';
import '../repositories/notes_repository.dart';
import '../entities/note_failure.dart';

/// Action use case: changes the text of a note after validating it.
final class UpdateNoteUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  UpdateNoteUseCase(this._repository);

  /// Gives the note with [id] the [text]; fails without calling the repository when [text] is blank.
  Future<Result<void, NoteFailure>> call(String id, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return Future<Result<void, NoteFailure>>.value(const Result.failure(NoteFailure.emptyText));
    return _repository.updateNote(id, trimmed);
  }
}
