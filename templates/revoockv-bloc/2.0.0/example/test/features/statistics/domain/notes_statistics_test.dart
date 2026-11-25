import 'package:example_app/features/statistics/domain/entities/note_facts.dart';
import 'package:example_app/features/statistics/domain/entities/notes_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts notes, words, notes added today, edited and pinned notes', () {
    final DateTime today = DateTime(2026, 11, 12, 18);
    final DateTime yesterday = DateTime(2026, 11, 11, 9);

    final NotesStatistics statistics = NotesStatistics.of(<NoteFacts>[
      NoteFacts(
        text: 'Buy milk',
        createdAt: DateTime(2026, 11, 12, 8),
        updatedAt: DateTime(2026, 11, 12, 8),
        isPinned: true,
      ),
      NoteFacts(
        text: ' Call   mom today ',
        createdAt: yesterday,
        updatedAt: DateTime(2026, 11, 12, 9),
        isPinned: false,
      ),
    ], now: today);

    expect(statistics.notes, 2);
    expect(statistics.words, 5);
    expect(statistics.addedToday, 1);
    expect(statistics.edited, 1);
    expect(statistics.pinned, 1);
  });

  test('no notes — all zero', () {
    final NotesStatistics statistics = NotesStatistics.of(const <NoteFacts>[], now: DateTime(2026));

    expect(
      <int>[statistics.notes, statistics.words, statistics.addedToday, statistics.edited, statistics.pinned],
      <int>[0, 0, 0, 0, 0],
    );
  });
}
