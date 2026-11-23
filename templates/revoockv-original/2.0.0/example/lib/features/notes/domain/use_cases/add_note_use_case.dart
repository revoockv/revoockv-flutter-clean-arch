import 'package:example_app/core/domain/entities/result.dart';
import '../repositories/notes_repository.dart';
import '../entities/note_failure.dart';

/// Action use case: adds a note after validating its text.
final class AddNoteUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  AddNoteUseCase(this._repository);

  /// Adds a note with [text]; fails without calling the repository when [text] is blank.
  Future<Result<void, NoteFailure>> call(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return Future<Result<void, NoteFailure>>.value(const Result.failure(NoteFailure.emptyText));
    return _repository.addNote(trimmed);
  }
}
