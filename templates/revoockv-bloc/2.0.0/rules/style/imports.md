# Imports conventions (required)

flutter_bloc:
- `import 'package:flutter_bloc/flutter_bloc.dart';` — in blocs, pages, widgets and DI files; it exports `bloc` and
  `context.read/watch/select`.
- Never in `data/` or `domain/`.

Result:
- `import 'package:<your_app>/core/domain/entities/result.dart';` (adjust to your actual package name)

Flutter foundation helpers (`listEquals` in states): `import 'package:flutter/foundation.dart' show listEquals;` —
always with `show`.

Use cases and repositories:
- Use cases: blocs (they call them), pages (they create the blocs) and DI files, with relative paths:
  `import '../../domain/use_cases/add_note_use_case.dart';`.
- Repositories and the data layer: only the DI files. Widgets import none of them (linter: `import_violation`, with
  `use_case_imports_in = ["blocs", "pages"]`).

Inside a feature — relative imports; core — `package:<your_app>/core/...`.
