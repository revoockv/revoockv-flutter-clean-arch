/// The app's storage: tables of rows keyed by `id`.
///
/// A stand-in for a real database (SQLite, Isar, a server): data sources of every feature read and write through it.
abstract interface class AppDatabase {
  /// Name of the key every row has.
  static const String idColumn = 'id';

  /// The rows of [table] right away, then after every change.
  Stream<List<Map<String, Object?>>> watchTable(String table);

  /// Adds [row] (it has an `id`) to [table].
  Future<void> insert(String table, Map<String, Object?> row);

  /// Replaces the row with [id] in [table] by [row]; throws [RowNotFoundException] when there is no such row.
  Future<void> update(String table, String id, Map<String, Object?> row);

  /// Removes the row with [id] from [table]; throws [RowNotFoundException] when there is no such row.
  Future<void> delete(String table, String id);

  /// Closes every table stream.
  Future<void> close();
}

/// No row with the id asked for — like a database's "not found".
final class RowNotFoundException implements Exception {
  static const String _message = 'RowNotFoundException: no row ';
  static const String _inTable = ' in ';

  /// The table looked in.
  final String table;

  /// The id that was not found.
  final String id;

  /// Creates the exception.
  const RowNotFoundException(this.table, this.id);

  @override
  String toString() => '$_message$id$_inTable$table';
}
