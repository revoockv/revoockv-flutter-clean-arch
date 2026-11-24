# Widget rules

Reading and reacting to state: `reactive_state_syntax.md`. UI state and who calls use cases: `controllers.md`.
Constants: `rules/style/constants.md`.

- Pages, wrappers and dumb widgets: `wrappers.md`.
- Prefer `StatelessWidget`. `WatchingWidget` only for pages and wrappers — they call `watch…()` /
  `registerHandler()` / `createOnce()` (linter: `watching_widget`). In a `StatelessWidget` / `StatefulWidget` these
  calls throw an assertion error at runtime.
- `StatefulWidget` only where the framework needs a `State`: `AnimationController` (`vsync`), `didUpdateWidget`, or a
  dumb widget that owns a plain Flutter controller (`TextEditingController`) from `initState` to `dispose`.
  Never `setState`: UI state lives in `ValueNotifier`s.
- A widget that only receives a Flutter controller (`TextField(controller: textController)`) is a `StatelessWidget`.
- No helper methods returning widgets: make a `StatelessWidget` in `widgets/`. Small widgets used only by one parent
  may be private (`_PrivateWidget`) in the parent's file; each declares its own `static const` fields.
- Class and file names end with `Widget` / `_widget.dart`, wrappers with `Wrapper` / `_wrapper.dart`, pages with
  `Page` / `_page.dart`.
- No inline callbacks: `onPressed`, `onChanged`, `onSubmitted`… reference a private method (`_onPressed`).
- Color constants are named by purpose (`_errorTextColor`), never by color (`_red`).
- Widgets in `widgets/` are dumb: data, texts and callbacks, no `watch`, use cases, controllers or translations
  (linter: `widgets_dumb`); their wrapper selects (`wrappers.md`). They live in their feature; only plain-Flutter
  widgets several features use go to `lib/core/presentation/widgets/` (`widget_placement.md`).
- Use case getters come from `<feature>_getters.dart`, never from domain imports.
- Snackbars, dialogs and navigation in response to state never go into `build()`.
- After changes run `flutter analyze` and the linter; add new files to git when the project is a repository.
