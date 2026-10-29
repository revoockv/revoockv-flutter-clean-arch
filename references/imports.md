# Imports conventions (required)

watch_it / get_it:
- `import 'package:watch_it/watch_it.dart';` — in widgets, DI files and getters; it re-exports get_it and provides `di`.
- Never import `package:get_it/get_it.dart` or `package:watch_it/...` in `data/` or `domain/`.

Result:
- `import 'package:<your_app>/core/domain/entities/result.dart';` (adjust to your actual package name)

ValueNotifier / ValueListenable:
- Domain and use cases: `import 'package:flutter/foundation.dart' show ValueListenable;`
- Repository implementations: `import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;`
- Always import with `show`, never the whole package.

Use cases and repositories:
- Only the DI files in `presentation/di/` import them, with relative paths: `import '../../domain/use_cases/add_note_use_case.dart';`.
- Pages, widgets and controllers never import use cases, repositories or the data layer: pages and widgets import `../di/<feature>_getters.dart`, controllers get use cases as constructor functions (linter: `import_violation`).

Inside a feature — relative imports; core — `package:<your_app>/core/...`.
