import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../app_test_app.dart';
import '../../../settle.dart';
import '../fake_notes_data_sources.dart';

const Widget notesPage = Scaffold(body: NotesPage());

void main() {
  testWidgets('adds, edits and deletes a note', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(notesPage));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Buy milk'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsNothing, reason: 'the field is cleared');

    await tester.tap(find.widgetWithText(ListTile, 'Buy milk'));
    await settle(tester);
    expect(find.text('Edit note'), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Buy bread');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Buy bread'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('blank note shows the error as a snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(notesPage));
    await settle(tester);

    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Note text must not be empty'), findsOneWidget);
  });

  testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(notesPage, notes: FailingNotesDataSource()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Could not add the note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsOneWidget);
  });

  testWidgets('a load error is shown instead of the list', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(notesPage, notes: BrokenStreamNotesDataSource()));
    await settle(tester);

    expect(find.text('Could not load the notes'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
  });
}
