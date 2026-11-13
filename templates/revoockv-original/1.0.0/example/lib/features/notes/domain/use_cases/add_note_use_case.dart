import 'package:example_app/core/domain/entities/result.dart';
import '../repositories/notes_repository.dart';

/// Action use case: adds a note after validating its text.
final class AddNoteUseCase {
  /// Message returned when the text is empty.
  static const String _emptyTextMessage = 'Note text must not be empty';

  final NotesRepository _repository;

  /// Creates the use case.
  AddNoteUseCase(this._repository);

  /// Adds a note with [text]; fails without calling the repository when [text] is blank.
  Future<Result<void>> call(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return Future<Result<void>>.value(const Result.failure(_emptyTextMessage));
    return _repository.addNote(trimmed);
  }
}
