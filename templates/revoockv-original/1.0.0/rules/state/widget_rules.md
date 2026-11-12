# Widget rules

Reading and reacting to state: `reactive_state_syntax.md`. UI state and who calls use cases: `controllers.md`.
Constants: `rules/style/constants.md`.

- Prefer `StatelessWidget`. `WatchingWidget` only when the widget calls `watch()` / `registerHandler()` or owns a
  controller with `createOnce()` (linter: `watching_widget`); keep it at the smallest widget that must rebuild.
  In a `StatelessWidget` / `StatefulWidget` these calls throw an assertion error at runtime.
- `StatefulWidget` only where the framework needs a `State`: `AnimationController` (`vsync`), `didUpdateWidget`.
  Even then no `setState`: UI state lives in `ValueNotifier`s.
- A widget that only receives a Flutter controller (`TextField(controller: textController)`) is a `StatelessWidget`.
- No helper methods returning widgets: make a `StatelessWidget` in `widgets/`. Small widgets used only by one parent
  may be private (`_PrivateWidget`) in the parent's file; each declares its own `static const` fields.
- Class and file names end with `Widget` / `_widget.dart`, pages with `Page` / `_page.dart`.
- No inline callbacks: `onPressed`, `onChanged`, `onSubmitted`… reference a private method (`_onPressed`).
- Color constants are named by purpose (`_errorTextColor`), never by color (`_red`).
- Leaf widgets (buttons, tiles, list items) get data and callbacks, at most a `ValueListenable` to show — never use
  cases or a feature controller.
- Use case getters come from `<feature>_getters.dart`, never from domain imports.
- Snackbars, dialogs and navigation in response to state never go into `build()`.
- After changes run `flutter analyze` and the linter; add new files to git when the project is a repository.
