import 'dart:async';


import 'app_database.dart';

/// [AppDatabase] in memory: behaves like a database (latency, change streams, missing rows fail) without storing
/// anything on disk.
final class InMemoryAppDatabase implements AppDatabase {
  /// How long every call waits, like I/O.
  static const Duration defaultLatency = Duration(milliseconds: 120);

  /// Wait of every call; tests pass [Duration.zero].
  final Duration latency;

  final Map<String, List<Map<String, Object?>>> _tables = <String, List<Map<String, Object?>>>{};

  final Map<String, StreamController<List<Map<String, Object?>>>> _changes =
      <String, StreamController<List<Map<String, Object?>>>>{};

  /// Creates an empty database.
  InMemoryAppDatabase({this.latency = defaultLatency});

  /// Emits the rows right away, then every change; subscribes synchronously, so no change is lost.
  @override
  Stream<List<Map<String, Object?>>> watchTable(String table) =>
      Stream<List<Map<String, Object?>>>.multi((MultiStreamController<List<Map<String, Object?>>> listener) {
        listener.add(_rows(table));
        final StreamSubscription<List<Map<String, Object?>>> sub = _changesOf(table).stream.listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = sub.cancel;
      });

  @override
  Future<void> insert(String table, Map<String, Object?> row) async {
    await Future<void>.delayed(latency);
    _table(table).add(Map<String, Object?>.unmodifiable(row));
    _emit(table);
  }

  @override
  Future<void> update(String table, String id, Map<String, Object?> row) async {
    await Future<void>.delayed(latency);
    final List<Map<String, Object?>> rows = _table(table);
    rows[_indexOf(table, id)] = Map<String, Object?>.unmodifiable(row);
    _emit(table);
  }

  @override
  Future<void> delete(String table, String id) async {
    await Future<void>.delayed(latency);
    _table(table).removeAt(_indexOf(table, id));
    _emit(table);
  }

  @override
  Future<void> close() async {
    for (final StreamController<List<Map<String, Object?>>> changes in _changes.values) {
      await changes.close();
    }
  }

  List<Map<String, Object?>> _table(String table) => _tables.putIfAbsent(table, () => <Map<String, Object?>>[]);

  List<Map<String, Object?>> _rows(String table) => List<Map<String, Object?>>.unmodifiable(_table(table));

  StreamController<List<Map<String, Object?>>> _changesOf(String table) =>
      _changes.putIfAbsent(table, StreamController<List<Map<String, Object?>>>.broadcast);

  int _indexOf(String table, String id) {
    final int index = _table(table).indexWhere((Map<String, Object?> row) => row[AppDatabase.idColumn] == id);
    if (index < 0) throw RowNotFoundException(table, id);
    return index;
  }

  void _emit(String table) {
    _changesOf(table).add(_rows(table));
  }
}
