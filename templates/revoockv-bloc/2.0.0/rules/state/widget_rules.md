# Widget rules

Reading state, reacting to it and sending actions: `blocs.md`. Constants: `rules/style/constants.md`.

- Prefer `StatelessWidget`. `StatefulWidget` only to own a Flutter controller (`TextEditingController`,
  `AnimationController`) created in `initState` and disposed in `dispose` (linter: `controller_lifecycle`). No
  `setState`: what changes on screen is a bloc's state.
- Pages, wrappers and dumb widgets: `wrappers.md`. Keep rebuilds low: a wrapper per part that changes on its own
  selects exactly what its dumb widget shows; the page only reacts (`BlocListener`) and does not rebuild.
- No helper methods returning widgets: make a `StatelessWidget` in `widgets/`. Small widgets used only by one parent
  may be private (`_PrivateWidget`) in the parent's file; each declares its own `static const` fields.
- Class and file names end with `Widget` / `_widget.dart`, wrappers with `Wrapper` / `_wrapper.dart`, pages with
  `Page` / `_page.dart`.
- No inline callbacks: `onPressed`, `onChanged`, `onSubmitted`… and `listenWhen`, `listener`, `selector`, `create`
  reference private methods.
- Color constants are named by purpose (`_errorTextColor`), never by color (`_red`).
- Widgets in `widgets/` are dumb: data, texts and callbacks — no `context.read/watch/select`, blocs, use cases or
  translations (linter: `widgets_dumb`).
- After an `await` in a widget, check `context.mounted` before using the context (linter: `async_gap_context_mounted`).
- After changes run `flutter analyze` and the linter; add new files to git when the project is a repository.
