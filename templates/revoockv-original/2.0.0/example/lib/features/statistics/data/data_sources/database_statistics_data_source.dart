import 'package:example_app/core/data/data_sources/app_database.dart';

import '../models/note_facts_model.dart';
import 'statistics_data_source.dart';

/// Reads the `notes` table of the [AppDatabase]; never writes.
final class DatabaseStatisticsDataSource implements StatisticsDataSource {
  final AppDatabase _database;

  /// Creates the data source.
  DatabaseStatisticsDataSource({required this._database});

  @override
  Stream<List<NoteFactsModel>> watchNoteFacts() => _database.watchTable(NoteFactsModel.table).map(_toModels);

  static List<NoteFactsModel> _toModels(List<Map<String, Object?>> rows) => rows.map(NoteFactsModel.fromRow).toList();
}
