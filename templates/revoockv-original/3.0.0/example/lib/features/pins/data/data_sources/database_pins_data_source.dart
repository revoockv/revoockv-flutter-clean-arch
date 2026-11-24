import 'package:example_app/core/data/data_sources/app_database.dart';

import '../models/pin_model.dart';
import 'pins_data_source.dart';

/// Pins in the `pins` table of the [AppDatabase].
final class DatabasePinsDataSource implements PinsDataSource {
  final AppDatabase _database;

  /// Creates the data source.
  DatabasePinsDataSource({required this._database});

  @override
  Stream<List<PinModel>> watchPins() => _database.watchTable(PinModel.table).map(_toModels);

  @override
  Future<void> add(PinModel pin) => _database.insert(PinModel.table, pin.toRow());

  @override
  Future<void> remove(String noteId) => _database.delete(PinModel.table, noteId);

  static List<PinModel> _toModels(List<Map<String, Object?>> rows) => rows.map(PinModel.fromRow).toList();
}
