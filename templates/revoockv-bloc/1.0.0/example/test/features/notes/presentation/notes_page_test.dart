import 'package:example_app/features/notes/data/data_sources/in_memory_notes_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_notes_data_sources.dart';
import '../notes_test_app.dart';

/// Lets streams deliver their events, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  await tester.pump();
}

void main() {
  testWidgets('adds and deletes a note', (WidgetTester tester) async {
    await tester.pumpWidget(notesTestApp(InMemoryNotesDataSource()));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Buy milk'), findsNWidgets(1));
    expect(find.widgetWithText(TextField, 'Buy milk'), findsNothing, reason: 'the field is cleared');

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('blank note shows the error as a snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(notesTestApp(InMemoryNotesDataSource()));
    await settle(tester);

    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Note text must not be empty'), findsOneWidget);
  });

  testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
    await tester.pumpWidget(notesTestApp(FailingNotesDataSource()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Could not add the note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsOneWidget);
  });

  testWidgets('a load error is shown instead of the list', (WidgetTester tester) async {
    await tester.pumpWidget(notesTestApp(BrokenStreamNotesDataSource()));
    await settle(tester);

    expect(find.text('Could not load the notes'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
  });
}
