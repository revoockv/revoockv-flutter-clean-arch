import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/notes/domain/use_cases/add_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/update_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/watch_notes_use_case.dart';
import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:example_app/features/notes/presentation/widgets/add_note_widget.dart';
import 'package:example_app/features/notes/presentation/widgets/note_tile_widget.dart';
import 'package:example_app/features/notes/presentation/widgets/notes_list_widget.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:example_app/features/statistics/presentation/widgets/statistic_tile_widget.dart';
import 'package:example_app/features/statistics/presentation/widgets/statistics_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_app.dart';
import 'settle.dart';

/// How many times every widget type was built since [reset].
final class BuildCounter {
  final Map<Type, int> _builds = <Type, int>{};

  /// Starts counting; stops when the test ends.
  void start() {
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) =>
        _builds.update(element.widget.runtimeType, (int count) => count + 1, ifAbsent: () => 1);
    addTearDown(() => debugOnRebuildDirtyWidget = null);
  }

  /// Forgets what was counted.
  void reset() => _builds.clear();

  /// Builds of widgets of type [T].
  int of<T>() => _builds[T] ?? 0;
}

/// The notes stored now, read through the providers above [page].
Future<List<Note>> notesNow(WidgetTester tester, Type page) async {
  final Result<List<Note>, NoteFailure> result =
      await tester.element(find.byType(page)).read<WatchNotesUseCase>()().first;
  return switch (result) {
    SuccessResult<List<Note>, NoteFailure>(:final List<Note> value) => value,
    FailureResult<List<Note>, NoteFailure>() => const <Note>[],
  };
}

void main() {
  testWidgets('an edited note rebuilds only its own tile; a new note rebuilds the list', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(const Scaffold(body: NotesPage())));
    final BuildContext context = tester.element(find.byType(NotesPage));
    await tester.runAsync(() async {
      for (final String text in <String>['One', 'Two', 'Three']) {
        await context.read<AddNoteUseCase>()(text);
      }
    });
    await settle(tester);
    final BuildCounter builds = BuildCounter()..start();

    final List<Note> notes = (await tester.runAsync(() => notesNow(tester, NotesPage)))!;
    await tester.runAsync(() => context.read<UpdateNoteUseCase>()(notes[1].id, 'Two, edited'));
    await settle(tester);
    expect(find.text('Two, edited'), findsOneWidget);
    expect(builds.of<NoteTileWidget>(), 1);
    expect(builds.of<NotesListWidget>(), 0);
    expect(builds.of<AddNoteWidget>(), 0);

    builds.reset();
    await tester.runAsync(() => context.read<AddNoteUseCase>()('Four'));
    await settle(tester);
    expect(find.text('Four'), findsOneWidget);
    // A new id rebuilds the list, and the list builds its visible items again (Flutter always rebuilds the children
    // of a rebuilt list); the keys keep their elements, nothing is created anew but the new note's.
    expect(builds.of<NotesListWidget>(), 1);
    expect(builds.of<NoteTileWidget>(), 4);
    expect(builds.of<AddNoteWidget>(), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a statistic rebuilds only when its own number changes', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(const Scaffold(body: StatisticsPage())));
    final BuildContext context = tester.element(find.byType(StatisticsPage));
    await tester.runAsync(() => context.read<AddNoteUseCase>()('One word'));
    await settle(tester);
    final BuildCounter builds = BuildCounter()..start();

    final List<Note> notes = (await tester.runAsync(() => notesNow(tester, StatisticsPage)))!;
    await tester.runAsync(() => context.read<UpdateNoteUseCase>()(notes.single.id, 'One more word'));
    await settle(tester);
    // The words grow and the note becomes edited; notes and added today stay.
    expect(builds.of<StatisticTileWidget>(), 2);
    expect(builds.of<StatisticsListWidget>(), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
