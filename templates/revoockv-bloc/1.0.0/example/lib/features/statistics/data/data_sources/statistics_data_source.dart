import '../models/note_facts_model.dart';

/// What statistics read from the storage.
abstract interface class StatisticsDataSource {
  /// The facts of every note right away, then after every change.
  Stream<List<NoteFactsModel>> watchNoteFacts();
}
