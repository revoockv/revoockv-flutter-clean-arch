import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/notes/domain/use_cases/add_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/update_note_use_case.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter_test/flutter_test.dart';

/// Records calls instead of storing notes.
final class FakeNotesRepository implements NotesRepository {
  final List<String> added = <String>[];

  final List<String> updated = <String>[];

  final ValueNotifier<ResultState<List<Note>>> _notes =
      ValueNotifier<ResultState<List<Note>>>(const ResultState.success(<Note>[]));

  /// The same instance on every call — like the real repository.
  @override
  ValueListenable<ResultState<List<Note>>> watchNotes() => _notes;

  @override
  Future<Result<void>> addNote(String text) async {
    added.add(text);
    return Result.ok;
  }

  @override
  Future<Result<void>> updateNote(String id, String text) async {
    updated.add('$id:$text');
    return Result.ok;
  }

  @override
  Future<Result<void>> deleteNote(String id) async => Result.ok;
}

void main() {
  late FakeNotesRepository repository;

  setUp(() => repository = FakeNotesRepository());

  test('blank text fails without calling the repository', () async {
    expect((await AddNoteUseCase(repository)('   ')).isFailure, isTrue);
    expect((await UpdateNoteUseCase(repository)('a', '  ')).isFailure, isTrue);
    expect(repository.added, isEmpty);
    expect(repository.updated, isEmpty);
  });

  test('text is trimmed and passed to the repository', () async {
    expect((await AddNoteUseCase(repository)('  Buy milk ')).isSuccess, isTrue);
    expect((await UpdateNoteUseCase(repository)('a', ' Buy bread ')).isSuccess, isTrue);
    expect(repository.added, <String>['Buy milk']);
    expect(repository.updated, <String>['a:Buy bread']);
  });
}
