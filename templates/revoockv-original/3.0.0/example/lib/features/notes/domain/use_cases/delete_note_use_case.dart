import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';

import '../entities/note_failure.dart';
import '../repositories/notes_repository.dart';

/// Action use case: deletes a note and its pin.
///
/// Uses the pins feature through its domain (`PinsRepository`): the notes feature depends on pins, pins know nothing
/// about notes.
final class DeleteNoteUseCase {
  final NotesRepository _notes;

  final PinsRepository _pins;

  /// Creates the use case.
  DeleteNoteUseCase(this._notes, this._pins);

  /// Deletes the note with [id], then its pin. A pin left behind when unpinning fails does no harm — a pin counts
  /// only for a note that exists — so only the deletion decides the result.
  Future<Result<void, NoteFailure>> call(String id) async {
    final Result<void, NoteFailure> deleted = await _notes.deleteNote(id);
    if (deleted.isSuccess) await _pins.unpin(id);
    return deleted;
  }
}
