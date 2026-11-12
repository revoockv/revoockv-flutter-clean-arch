import 'package:example_app/features/notes/data/data_sources/in_memory_notes_data_source.dart';
import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import '../fake_notes_data_sources.dart';
import '../notes_test_di.dart';

/// Lets streams deliver their events, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  await tester.pump();
}

void main() {
  tearDown(() async => di.reset());

  testWidgets('adds and deletes a note', (WidgetTester tester) async {
    await registerAndInitNotesForTest(InMemoryNotesDataSource());
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blank note shows the error as a snackbar', (WidgetTester tester) async {
    await registerAndInitNotesForTest(InMemoryNotesDataSource());
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await settle(tester);

    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Note text must not be empty'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed add keeps the text and shows the error', (WidgetTester tester) async {
    await registerAndInitNotesForTest(FailingNotesDataSource());
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Could not add the note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Buy milk'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a load error is shown instead of the list', (WidgetTester tester) async {
    await registerAndInitNotesForTest(BrokenStreamNotesDataSource());
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await settle(tester);

    expect(find.text('Could not load the notes'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
