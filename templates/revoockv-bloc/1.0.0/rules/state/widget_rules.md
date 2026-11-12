# Widget rules

Reading state, reacting to it and sending actions: `blocs.md`. Constants: `rules/style/constants.md`.

- Prefer `StatelessWidget`. `StatefulWidget` only to own a Flutter controller (`TextEditingController`,
  `AnimationController`) created in `initState` and disposed in `dispose` (linter: `controller_lifecycle`). No
  `setState`: what changes on screen is a bloc's state.
- Keep rebuilds low: the widget that shows a value watches it (`context.select` for one field), parents pass nothing that
  changes; a widget that only reacts uses `BlocListener` and does not rebuild.
- No helper methods returning widgets: make a `StatelessWidget` in `widgets/`. Small widgets used only by one parent
  may be private (`_PrivateWidget`) in the parent's file; each declares its own `static const` fields.
- Class and file names end with `Widget` / `_widget.dart`, pages with `Page` / `_page.dart`.
- No inline callbacks: `onPressed`, `onChanged`, `onSubmitted`… and `listenWhen`, `listener`, `selector`, `create`
  reference private methods.
- Color constants are named by purpose (`_errorTextColor`), never by color (`_red`).
- Leaf widgets (buttons, tiles, list items) get data and callbacks — no `context.read` of blocs or use cases.
- After an `await` in a widget, check `context.mounted` before using the context (linter: `async_gap_context_mounted`).
- After changes run `flutter analyze` and the linter; add new files to git when the project is a repository.
