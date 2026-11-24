import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watchTable emits the rows right away and after every change', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);
    final List<List<Map<String, Object?>>> seen = <List<Map<String, Object?>>>[];
    final sub = database.watchTable('notes').listen(seen.add);

    await database.insert('notes', <String, Object?>{'id': 'a', 'text': 'One'});
    await database.update('notes', 'a', <String, Object?>{'id': 'a', 'text': 'Two'});
    await database.delete('notes', 'a');
    await Future<void>.delayed(Duration.zero);

    expect(seen.map((List<Map<String, Object?>> rows) => rows.map((Map<String, Object?> r) => r['text']).toList()),
        <List<Object?>>[<Object?>[], <Object?>['One'], <Object?>['Two'], <Object?>[]]);
    await sub.cancel();
    await database.close();
  });

  test('an unknown id fails like a database', () async {
    final InMemoryAppDatabase database = InMemoryAppDatabase(latency: Duration.zero);

    expect(database.update('notes', 'x', <String, Object?>{'id': 'x'}), throwsA(isA<RowNotFoundException>()));
    expect(database.delete('notes', 'x'), throwsA(isA<RowNotFoundException>()));
    await database.close();
  });
}
