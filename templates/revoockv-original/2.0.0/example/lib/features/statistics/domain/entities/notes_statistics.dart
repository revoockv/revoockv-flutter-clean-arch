import 'note_facts.dart';

/// Numbers about all notes.
final class NotesStatistics {
  static final RegExp _wordSeparator = RegExp(r'\s+');

  /// How many notes there are.
  final int notes;

  /// Words in all notes.
  final int words;

  /// Notes written today.
  final int addedToday;

  /// Notes changed after they were written.
  final int edited;

  /// Creates the numbers.
  const NotesStatistics({required this.notes, required this.words, required this.addedToday, required this.edited});

  /// Counts [facts]; "today" is the day of [now].
  factory NotesStatistics.of(List<NoteFacts> facts, {required DateTime now}) => NotesStatistics(
        notes: facts.length,
        words: facts.fold<int>(0, (int sum, NoteFacts note) => sum + _wordsOf(note.text)),
        addedToday: facts.where((NoteFacts note) => _sameDay(note.createdAt, now)).length,
        edited: facts.where((NoteFacts note) => note.updatedAt != note.createdAt).length,
      );

  static int _wordsOf(String text) {
    final String trimmed = text.trim();
    return trimmed.isEmpty ? 0 : trimmed.split(_wordSeparator).length;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
