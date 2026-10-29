import 'dart:async';

import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/presentation/controllers/notes_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a controller whose actions are plain functions — no DI.
NotesController controllerWith({
  Future<Result<void>> Function(String text)? add,
  Future<Result<void>> Function(String id)? delete,
}) =>
    NotesController(add: add ?? succeed, delete: delete ?? succeed);

Future<Result<void>> succeed(String _) async => Result.ok;

void main() {
  test('a failure becomes FailureResultState with the message', () async {
    final NotesController controller =
        controllerWith(add: (String text) async => const Result.failure('Could not add'));

    controller.text.text = 'x';
    await controller.addNote();

    expect(controller.value, isA<FailureResultState<void>>());
    expect((controller.value as FailureResultState<void>).message, 'Could not add');
    expect(controller.text.text, 'x', reason: 'a failed note keeps its text');
    controller.dispose();
  });

  test('a successful add passes the text and clears the field', () async {
    final List<String> added = <String>[];
    final NotesController controller = controllerWith(
      add: (String text) async {
        added.add(text);
        return Result.ok;
      },
    );

    controller.text.text = 'Buy milk';
    await controller.addNote();

    expect(added, <String>['Buy milk']);
    expect(controller.text.text, isEmpty);
    expect(controller.value.isSuccess, isTrue);
    controller.dispose();
  });

  test('the same failure twice notifies twice', () async {
    final NotesController controller =
        controllerWith(add: (String text) async => const Result.failure('Could not add'));
    int failures = 0;
    controller.addListener(() => failures += controller.value.isFailure ? 1 : 0);

    await controller.addNote();
    await controller.addNote();

    expect(failures, 2);
    controller.dispose();
  });

  test('a second action while one runs is ignored', () async {
    final Completer<Result<void>> first = Completer<Result<void>>();
    final List<String> deleted = <String>[];
    final NotesController controller = controllerWith(
      delete: (String id) {
        deleted.add(id);
        return first.future;
      },
    );

    final Future<void> running = controller.deleteNote('1');
    expect(controller.value.isLoading, isTrue);

    await controller.deleteNote('2');
    expect(deleted, <String>['1']);

    first.complete(Result.ok);
    await running;
    expect(controller.value.isSuccess, isTrue);
    controller.dispose();
  });
}
