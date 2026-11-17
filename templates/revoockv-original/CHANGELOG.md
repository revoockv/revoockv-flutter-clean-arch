# revoockv-original — changelog

Versions of this template. The skill itself has its own versions (`CHANGELOG.md` in the skill root).

## [2.0.0]

- Made from revoockv-original@1.0.0.
- Few rebuilds (`rules/state/rebuilds.md`): watch only what a widget shows; a part of a value through
  `watchPropertyValue(_partOf, target: …)`, never `watch(x).value.part` (lint `watch_select`); fast state (timers,
  levels, positions, typed text) only in the widget that draws it; data one area shows is watched in that area.
- Where a widget lives (`rules/state/widget_placement.md`): in its feature by default; `lib/core/presentation/widgets/`
  holds only plain-Flutter widgets several features use (lint `core_widgets_pure`, `[lint.params] core_widget_dirs`).
  Leaf widgets are pure: data and callbacks, no watch.
- Example: `_AddButtonWidget` selects `isLoading` with `watchPropertyValue`.

## [1.0.0] - 2026-11-12

- The rules of the skill up to 0.9.0, split by topic (`rules/<topic>/`), with `template.toml` and the notes app as
  `example/`.
- Shorter rules (3199 → 2344 lines): code that equals the example is a link to `example/<path>`, the auth feature is
  split by layer (`examples/auth_{domain,data,presentation}.md`), `decisions.md` gives the answer itself, and
  `workflow.md` / `widget_rules.md` no longer repeat `controllers.md` and `reactive_state_syntax.md`.
- Example: the app of `docs/example_app.md` — notes (add, edit, delete) and statistics over one placeholder
  `AppDatabase` in core; the API server example and the `http` topic are removed.
