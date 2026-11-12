import 'package:example_app/features/notes/presentation/controllers/notes_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with an empty note and idle actions', () {
    final NotesController notesController = NotesController();

    expect(notesController.noteTextController.text, isEmpty);
    expect(notesController.addingStateController.value.isIdle, isTrue);
    expect(notesController.deletingStateController.value.isIdle, isTrue);
    expect(notesController.isDisposed, isFalse);
    notesController.dispose();
  });

  test('dispose marks the controller as disposed', () {
    final NotesController notesController = NotesController()..dispose();

    expect(notesController.isDisposed, isTrue);
  });
}
