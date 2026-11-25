# Where a widget lives

Few rebuilds: `rebuilds.md`. Widget shape: `widget_rules.md`.

| The widget is used by… | It lives in |
|---|---|
| one feature (pure or watching) | `features/<feature>/presentation/widgets/` — **the default** |
| several features, plain Flutter | `lib/core/presentation/widgets/` |

A widget moves to `core` only when a **second feature** needs it, and only as plain Flutter. A pure widget of one
feature stays in that feature, even if it could be reused.

## Pure widgets (in a feature or in core)

Most leaf widgets — buttons, tiles, rows, indicators, dialogs — are pure:

- `StatelessWidget` (a `StatefulWidget` only to own a plain Flutter controller); no `watch`, no use cases, getters,
  feature controllers or translations (linter: `widgets_dumb`).
- They take the data they draw, their texts and callbacks (`onPressed`, `ValueChanged<T>`); their wrapper selects
  and passes the values (`wrappers.md`). In a feature they may take its entities.
- They are easy to test: a widget test with plain values, no DI.

## Core widgets

What `lib/core/presentation/widgets/` holds: widgets on plain Flutter that several features use (a confirm dialog,
an empty-state text, a time label, a level bar).

- Parameters are plain values: `String`, `num`, `bool`, `Duration`, `DateTime`, `Color`, `IconData`, `Widget` slots,
  callbacks — no entities of a feature, no `ResultState`, no `ValueListenable`.
- Every text comes in as a parameter (already translated); colors and styles from `Theme.of(context)`, spacing from
  `AppTheme`.
- Imports: `package:flutter/…`, other core widgets, `../theme.dart` — nothing from `features/`, `domain/`, `data/`,
  `di/`, `l10n/`, `controllers/`, `pages/`, no `watch_it` / `get_it` (linter: `core_widgets_pure`, folders in
  `[lint.params] core_widget_dirs`).
- Named by what it is (`ConfirmDialogWidget`, `TimeTextWidget`), not by a feature. Each has a widget test under
  `test/core/presentation/widgets/`.

## Moving a widget to core (a second feature needs it)

1. Entity parameters → the plain values it draws; callbacks lose the entity (`VoidCallback`).
2. Feature strings → parameters; each feature passes its own text.
3. Rename it by what it is, move it to `lib/core/presentation/widgets/`, move its test, run the linter.
