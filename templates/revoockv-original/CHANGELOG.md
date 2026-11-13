# revoockv-original — changelog

Versions of this template. The skill itself has its own versions (`CHANGELOG.md` in the skill root).

## [1.0.0] - 2026-11-12

- The rules of the skill up to 0.9.0, split by topic (`rules/<topic>/`), with `template.toml` and the notes app as
  `example/`.
- Shorter rules (3199 → 2344 lines): code that equals the example is a link to `example/<path>`, the auth feature is
  split by layer (`examples/auth_{domain,data,presentation}.md`), `decisions.md` gives the answer itself, and
  `workflow.md` / `widget_rules.md` no longer repeat `controllers.md` and `reactive_state_syntax.md`.
- Example: the app of `docs/example_app.md` — notes (add, edit, delete) and statistics over one placeholder
  `AppDatabase` in core; the API server example and the `http` topic are removed.
