import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/notes/domain/use_cases/delete_note_use_case.dart';
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';
import 'package:example_app/features/pins/domain/entities/pinned_notes.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deletes as told; records nothing else.
final class FakeNotesRepository implements NotesRepository {
  Result<void, NoteFailure> deleteResult = Result.ok;

  @override
  Stream<Result<List<Note>, NoteFailure>> watchNotes() => const Stream<Result<List<Note>, NoteFailure>>.empty();

  @override
  Future<Result<void, NoteFailure>> addNote(String text) async => Result.ok;

  @override
  Future<Result<void, NoteFailure>> updateNote(String id, String text) async => Result.ok;

  @override
  Future<Result<void, NoteFailure>> deleteNote(String id) async => deleteResult;
}

/// Records the unpinned notes.
final class FakePinsRepository implements PinsRepository {
  final List<String> unpinned = <String>[];

  @override
  Stream<Result<PinnedNotes, PinFailure>> watchPinnedNotes() => const Stream<Result<PinnedNotes, PinFailure>>.empty();

  @override
  Future<Result<void, PinFailure>> togglePin(String noteId) async => Result.ok;

  @override
  Future<Result<void, PinFailure>> unpin(String noteId) async {
    unpinned.add(noteId);
    return Result.ok;
  }
}

void main() {
  late FakeNotesRepository notes;
  late FakePinsRepository pins;

  setUp(() {
    notes = FakeNotesRepository();
    pins = FakePinsRepository();
  });

  test('a deleted note loses its pin — the notes feature uses the pins feature', () async {
    expect((await DeleteNoteUseCase(notes, pins)('n1')).isSuccess, isTrue);
    expect(pins.unpinned, <String>['n1']);
  });

  test('a note that could not be deleted keeps its pin', () async {
    notes.deleteResult = const Result.failure(NoteFailure.delete);

    expect((await DeleteNoteUseCase(notes, pins)('n1')).isFailure, isTrue);
    expect(pins.unpinned, isEmpty);
  });
}
