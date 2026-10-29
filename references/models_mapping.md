# Models mapping (required)

Data models (DTOs) represent technology-specific formats (JSON, DB schema, SDK objects).

Location:
- `lib/features/<feature>/data/models/`

Rules:
- Models must map both ways:
  - `Model.toEntity()` -> Domain entity
  - `factory Model.fromEntity(Entity)` -> Data model
- Keep mapping logic in the model class (not in presentation).
- Domain must not import Data models.

Ids:
- An entity id is created in the **data layer**, by the data source — the storage owns the ids. Repositories, use cases and the UI never invent ids.
- A data source that creates records itself generates a UUID v4: `static const Uuid _uuid = Uuid();` → `NoteModel(id: _uuid.v4(), text: text)` (package `uuid`). It stays unique across restarts, `di.reset()`, devices and sync — a counter in memory does not.
- A storage that issues its own ids (server, Firestore) returns them; the data source maps them into the model.
- `add` takes the data of the new record and returns the stored model with its id: `Future<NoteModel> add(String text);`.

Example:

```dart
/// Storage format of a user.
final class UserModel {
  /// Unique id of the user.
  final String id;

  /// Creates a user model.
  const UserModel({required this.id});

  /// Creates a model from a domain [entity].
  factory UserModel.fromEntity(User entity) => UserModel(id: entity.id);

  /// Converts the model into a domain entity.
  User toEntity() => User(id: id);
}
```