import 'package:flutter/material.dart';

import '../../domain/entities/notes_statistics.dart';
import '../wrappers/statistic_tile_wrapper.dart';
import '../wrappers/statistics_list_wrapper.dart';

/// Statistics tab: live numbers about the notes. Holds the labels; never rebuilds itself — every tile's wrapper
/// selects its own number.
final class StatisticsPage extends StatelessWidget {
  static const String _notesLabel = 'Notes';
  static const String _wordsLabel = 'Words';
  static const String _addedTodayLabel = 'Added today';
  static const String _editedLabel = 'Edited';

  /// Creates the page.
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatisticsListWrapper(
      tiles: <Widget>[
        StatisticTileWrapper(label: _notesLabel, countOf: _notesOf),
        StatisticTileWrapper(label: _wordsLabel, countOf: _wordsOf),
        StatisticTileWrapper(label: _addedTodayLabel, countOf: _addedTodayOf),
        StatisticTileWrapper(label: _editedLabel, countOf: _editedOf),
      ],
    );
  }

  static int _notesOf(NotesStatistics statistics) => statistics.notes;

  static int _wordsOf(NotesStatistics statistics) => statistics.words;

  static int _addedTodayOf(NotesStatistics statistics) => statistics.addedToday;

  static int _editedOf(NotesStatistics statistics) => statistics.edited;
}
