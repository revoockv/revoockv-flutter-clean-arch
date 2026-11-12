# Dartdoc standard (required)

Add Dartdoc (`///`) for every **public** declaration (linter: `dartdoc_public`):
- every public class, enum, mixin, extension
- every public method, top-level function, getter and setter — whatever it returns (`Future<void>`, `String?`, `Note`, …)
- every use case `call()`
- every public constructor, named and factory ones included (`/// Creates the …`)
- every public field and top-level variable (`/// Text of the note.`)
- DI functions (`registerAndInit<Feature>`, `registerAndInitCore`, `registerAndInit`) and getters in `<feature>_getters.dart`
- `init()` and `dispose()` of repositories and data sources
- any non-trivial private helper (not checked by the linter)

Not needed (the linter skips them):
- `@override` members — they inherit the documentation of the interface
- framework members: `build`, `initState`, `dispose` of a `State`, `createState`, `didUpdateWidget`, …, and `main`
- private names and the members of private classes (`_AddButtonWidget`)
- the unnamed constructor of a `sealed` class — it cannot be called outside its library

An annotation may stand between the comment and the declaration:

```dart
/// Resets the cache; used by tests only.
@visibleForTesting
void reset() {}
```

Keep docs concise:
- 1 sentence summary
- 1 sentence "when to use"
- Parameters/Returns only when useful
- mention side effects (subscriptions/IO/DI singletons) when present
