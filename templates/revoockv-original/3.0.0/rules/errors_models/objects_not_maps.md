# Objects, not maps (required)

Data that has a shape is a class, not a `Map`. A class names its fields, types each one, is checked by the
compiler, documented with Dartdoc and found by "find usages"; a `Map<String, dynamic>` is none of that, and a typo in
a key or a wrong cast fails only at run time. Flutter's own API follows this: `TextStyle`, `EdgeInsets`,
`RouteSettings` are objects, not maps.

## Short answer

| You have… | Use |
|---|---|
| A record with known fields (a song, settings, a request body) | an entity (domain) or a model (data), never `Map<String, dynamic>` |
| JSON or a storage format (Hive, SQLite rows, Firestore) | `Map` only at the storage boundary: the model in `data/models/` reads and writes it (`fromJson` / `toJson`, `fromRow`, `fromStored`), the data source only hands it between the storage and the model |
| A few named numbers that go together (settings, overrides) | a class with nullable fields and `copyWith`, not `Map<String, double>` |
| "A value per id" in an entity, a use case, a repository interface, a widget or a controller | an object that answers the question (`CoverCounts.of(songId)`, `UsageHistory.openedAt(songId)`) or a `List` of entities |
| A choice per item (an import decision per conflict) | a `List` of small objects (`ImportDecision(conflict, choice)`) or a field on the item |
| A lookup while computing (`songsById`, counting) | a local `Map` inside the function — fine |
| A cache inside a repository or a data source | a private `Map` field — fine; it never leaves the class |
| A third-party API that takes a map (HTTP headers, `jsonEncode`, a plugin's arguments) | build the map at that call, in the data source |

## Rules

1. `Map<String, dynamic>`, `Map<String, Object?>` and `Map<dynamic, dynamic>` appear only at the storage boundary:
   in `data/models/`, where the model turns the raw format into typed fields and back, and in `data/data_sources/`,
   which hands storage the model's `toJson()` and gives the model what storage returned (rows, a Hive value). A data
   source does not read or write the keys itself; repositories, domain and presentation never see a raw map.
2. No `Map` in public API: fields and getters of entities, parameters and return types of use cases and repository
   interfaces, constructor parameters of widgets, fields of controllers (and blocs/states). Wrap it in an object with
   methods that say what the map was for; keep the `Map` as its private field if a lookup is needed.
3. An entity that is built from a list keeps the index private: `CoverCounts.fromRecordings(recordings)` with a
   private `Map<String, int>` and `int of(String songId)`.
4. Several values sent between layers together are a class, even when only one function uses them — a record
   `({String songId, DateTime at})` is fine for a private helper, a class when it crosses a file.

The linter rule `objects_not_maps` finds record maps outside `data/models/` and `data/data_sources/`, and maps in the
public API of `domain/` and `presentation/`.

## Example

```dart
// Wrong: what keys are there? What does a missing id mean?
final class SongsWidget extends StatelessWidget {
  final Map<String, int> coverCounts;
}

// Right: the object answers the one question the widget asks.
final class CoverCounts {
  final Map<String, int> _bySongId;

  CoverCounts.fromRecordings(List<Recording> recordings) : _bySongId = <String, int>{} {
    for (final Recording recording in recordings) {
      _bySongId.update(recording.songId, (int count) => count + 1, ifAbsent: () => 1);
    }
  }

  /// Covers recorded of the song with [songId]; 0 when none.
  int of(String songId) => _bySongId[songId] ?? 0;
}
```
