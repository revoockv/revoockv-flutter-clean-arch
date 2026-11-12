# Constants and magic strings

## Constants — owning class, or core when shared

Never declare simple constants at file top level. Two places only:

**1. Used by one widget/class → private `static const` of that class:**

```dart
class VideoPlayerErrorWidget extends StatelessWidget {
  /// Size of the error icon in the error view.
  static const double _errorIconSize = 32;

  /// Label of the retry button.
  static const String _retryButtonLabel = 'Retry';
```

**2. Shared by several features (spacing, sizes, colors) → public `static const` of `AppTheme` in core:**

`lib/core/presentation/theme.dart`

```dart
import 'package:flutter/material.dart';

/// Values shared by more than one feature: spacing, sizes, colors.
///
/// A value used by a single widget stays a private `static const` of that widget.
final class AppTheme {
  /// Small gap between related elements.
  static const double spacingSmall = 8;

  /// Default padding of screens and cards.
  static const double spacingMedium = 16;

  /// Large gap between sections.
  static const double spacingLarge = 24;

  /// Seed color of the app color scheme.
  static const Color seedColor = Colors.indigo;

  const AppTheme._();
}
```

Use it as `AppTheme.spacingMedium` (import `package:<your_app>/core/presentation/theme.dart`). There are no per-feature theme files.

Rules:
- A value used by one class stays private in that class — do not move it to core "just in case".
- The same private constant (type, name, value) in two features is a shared value → move it to `AppTheme` (linter: `theme_import`).
- A private spacing constant (`_padding`, `_spacing`, `_gap`, `_margin`, `_inset`) with a value that `AppTheme` already has must use `AppTheme` (linter: `theme_import`).
- `magic_strings` and `magic_numbers` treat file-top-level `const Type _name = ...` as violations — only class-member `static const` is accepted.

## Magic Strings — Every Layer, No Exemptions

The `magic_strings` rule applies to every layer, the data layer included. JSON keys, CLI arguments, API parameter names, file extensions, separators and enum labels are private `static const` members of the class that uses them, like UI text and error messages:

```dart
final class NoteModel {
  /// JSON key of the note id.
  static const String _idKey = 'id';

  /// JSON key of the note text.
  static const String _textKey = 'text';

  NoteModel.fromJson(Map<String, dynamic> json)
    : id = json[_idKey] as String,
      text = json[_textKey] as String;
}

enum HistoryKind {
  image(_imageLabel),
  video(_videoLabel);

  static const String _imageLabel = 'Images';
  static const String _videoLabel = 'Video';

  /// Shown in the UI.
  final String label;

  const HistoryKind(this.label);
}
```

Log messages, `throw` and `assert` messages are no exception. In an interpolated string every text piece between the values is a constant; the string only joins constants and values:

```dart
static const String _searchSuccessLog = 'SearchJobs: success — ';
static const String _jobsToLog = ' job(s) → ';

_logger.i('$_searchSuccessLog${report.total}$_jobsToLog${report.path}');
```

Accepted by the linter: literals inside a `static const` / `static final` declaration (also when it spans several lines), directives (`import`, `export`, `part`), and pieces that are only whitespace or a number. A literal equal to an existing constant is still a violation — use the constant.
