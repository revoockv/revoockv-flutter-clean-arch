import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import '../../../app_test_di.dart';
import '../../../settle.dart';
import '../fake_notes_data_sources.dart';

const Widget notesApp = MaterialApp(home: Scaffold(body: NotesPage()));

void main() {
  tearDown(() async => di.reset());

  testWidgets('adds, edits and deletes a note', (WidgetTester tester) async {
    await registerAndInitForTest();
    await tester.pumpWidget(notesApp);
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Buy milk'), findsOneWidget);

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
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blank note shows the error as a snackbar', (WidgetTester tester) async {
    await registerAndInitForTest();
    await tester.pumpWidget(notesApp);
    await settle(tester);

    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Note text must not be empty'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
    await registerAndInitForTest(notes: FailingNotesDataSource());
    await tester.pumpWidget(notesApp);
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Could not add the note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a load error is shown instead of the list', (WidgetTester tester) async {
    await registerAndInitForTest(notes: BrokenStreamNotesDataSource());
    await tester.pumpWidget(notesApp);
    await settle(tester);

    expect(find.text('Could not load the notes'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
