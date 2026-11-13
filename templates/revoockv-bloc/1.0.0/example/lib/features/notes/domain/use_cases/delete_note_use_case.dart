import 'package:example_app/core/domain/entities/result.dart';
import '../repositories/notes_repository.dart';

/// Action use case: deletes a note.
final class DeleteNoteUseCase {
  final NotesRepository _repository;

  /// Creates the use case.
  DeleteNoteUseCase(this._repository);

  /// Deletes the note with [id].
  Future<Result<void>> call(String id) => _repository.deleteNote(id);
}
