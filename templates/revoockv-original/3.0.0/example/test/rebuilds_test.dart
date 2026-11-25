import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/notes/presentation/di/notes_getters.dart';
import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:example_app/features/notes/presentation/widgets/add_note_widget.dart';
import 'package:example_app/features/notes/presentation/widgets/note_tile_widget.dart';
import 'package:example_app/features/notes/presentation/widgets/notes_list_widget.dart';
import 'package:example_app/features/pins/presentation/di/pins_getters.dart';
import 'package:example_app/features/pins/presentation/widgets/pin_button_widget.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:example_app/features/statistics/presentation/widgets/statistic_tile_widget.dart';
import 'package:example_app/features/statistics/presentation/widgets/statistics_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import 'app_test_di.dart';
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

List<Note> notesNow() => switch (watchNotesUseCase().value) {
  SuccessResultState<List<Note>, NoteFailure>(:final List<Note> value) => value,
  _ => const <Note>[],
};

void main() {
  tearDown(() async => di.reset());

  testWidgets('an edited note rebuilds only its own tile; a new note rebuilds the list', (WidgetTester tester) async {
    await registerAndInitForTest();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NotesPage())));
    await tester.runAsync(() async {
      for (final String text in <String>['One', 'Two', 'Three']) {
        await addNoteUseCase(text);
      }
    });
    await settle(tester);
    final BuildCounter builds = BuildCounter()..start();

    await tester.runAsync(() => updateNoteUseCase(notesNow()[1].id, 'Two, edited'));
    await settle(tester);
    expect(find.text('Two, edited'), findsOneWidget);
    expect(builds.of<NoteTileWidget>(), 1);
    expect(builds.of<NotesListWidget>(), 0);
    expect(builds.of<AddNoteWidget>(), 0);

    builds.reset();
    await tester.runAsync(() => addNoteUseCase('Four'));
    await settle(tester);
    expect(find.text('Four'), findsOneWidget);
    // A new id rebuilds the list, and the list builds its visible items again (Flutter always rebuilds the children
    // of a rebuilt list); the keys keep their elements, nothing is created anew but the new note's.
    expect(builds.of<NotesListWidget>(), 1);
    expect(builds.of<NoteTileWidget>(), 4);
    expect(builds.of<AddNoteWidget>(), 0);

    builds.reset();
    await tester.runAsync(() => togglePinUseCase(notesNow()[2].id));
    await settle(tester);
    expect(builds.of<PinButtonWidget>(), 1, reason: 'the pin of another feature rebuilds only its own button');
    expect(builds.of<NoteTileWidget>(), 0);
    expect(builds.of<NotesListWidget>(), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a statistic rebuilds only when its own number changes', (WidgetTester tester) async {
    await registerAndInitForTest();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatisticsPage())));
    await tester.runAsync(() => addNoteUseCase('One word'));
    await settle(tester);
    final BuildCounter builds = BuildCounter()..start();

    // The words grow and the note becomes edited; notes and added today stay.
    await tester.runAsync(() => updateNoteUseCase(notesNow().single.id, 'One more word'));
    await settle(tester);
    expect(builds.of<StatisticTileWidget>(), 2); // words and edited
    expect(builds.of<StatisticsListWidget>(), 0);
    await tester.pumpWidget(const SizedBox());
  });
}
