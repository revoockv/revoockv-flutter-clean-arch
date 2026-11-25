# revoockv-original — changelog

Versions of this template. The skill itself has its own versions (`CHANGELOG.md` in the skill root).

## [3.0.0]

- Made from revoockv-original@2.1.0.

## [3.0.0]

- Made from revoockv-original@2.1.0.
- Pages, wrappers and dumb widgets (`rules/state/wrappers.md`): the page owns the controller, starts the actions and
  reacts, and never rebuilds; a wrapper in the new `presentation/wrappers/` folder selects with `watchPropertyValue`
  exactly what one dumb widget shows and starts nothing; widgets in `widgets/` are dumb — data, texts and callbacks,
  no watch_it, DI, use cases, controllers or translations; a dumb widget may own a plain Flutter controller
  (`StatefulWidget`). Parameter names as in Flutter (`hintText`, `addLabel`, `isAdding`, `onTap`, `onAddPressed`).
- Lists: the list wrapper selects the ids, an item wrapper (keyed by id) selects its item, so an edited note rebuilds
  one tile. `example/test/rebuilds_test.dart` counts builds with `debugOnRebuildDirtyWidget`.
- Lint: `widgets_dumb` and `wrappers_no_actions` on; `wrappers/` files and classes end with `_wrapper.dart` /
  `Wrapper`.
- One feature uses another (`rules/structure/feature_dependencies.md`): through its domain and its UI parts, never its
  data; no circles (lint `feature_dependencies`, on). The example gets the **pins** feature: notes use it
  (`DeleteNoteUseCase` unpins, the notes page places `PinButtonWrapper` into `NoteTileWidget(leading: …)`), and the
  statistics count notes and pins through their repositories instead of reading the `notes` table — their data source
  and model are gone, `NoteFacts` keeps only what they count (`isPinned` added), a "Pinned" number is shown.
- Example: wrappers for the add button, the list, every note and every number of the statistics; `Note` and
  `NotesStatistics` compare by value; the dumb widgets are the same files as in revoockv-bloc 2.0.0.

## [2.1.0]

- Made from revoockv-original@2.0.0.

## [2.1.0]

- Made from revoockv-original@2.0.0.
- Objects, not maps (`rules/errors_models/objects_not_maps.md`, `decisions.md`, `[choices] models`): data with a shape
  is a class; `Map<String, dynamic>` only at the storage boundary (models in `data/models/`, data sources); no `Map` in
  the public API of entities, use cases, repository interfaces, widgets and controllers (an object that answers by id
  or a `List` of entities); local lookups and private caches stay maps.
- Lint: `objects_not_maps` is on (`[lint] on`).
- Git (`rules/git/git_rules.md`): "Choose the type" — questions in order (the user's word, hotfix, fix, feature,
  refactor, docs, test/style) and wrong → right examples, decided before the branch is created; a merge into
  `develop` only after the user confirms the task is solved; corrections of a task stay on its branch.

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
