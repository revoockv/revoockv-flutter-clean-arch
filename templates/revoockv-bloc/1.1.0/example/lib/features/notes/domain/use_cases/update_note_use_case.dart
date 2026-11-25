import 'package:example_app/core/domain/entities/result.dart';
import '../repositories/notes_repository.dart';

/// Action use case: changes the text of a note after validating it.
final class UpdateNoteUseCase {
  /// Message returned when the text is empty.
  static const String _emptyTextMessage = 'Note text must not be empty';

  final NotesRepository _repository;

  /// Creates the use case.
  UpdateNoteUseCase(this._repository);

  /// Gives the note with [id] the [text]; fails without calling the repository when [text] is blank.
  Future<Result<void>> call(String id, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return Future<Result<void>>.value(const Result.failure(_emptyTextMessage));
    return _repository.updateNote(id, trimmed);
  }
}
