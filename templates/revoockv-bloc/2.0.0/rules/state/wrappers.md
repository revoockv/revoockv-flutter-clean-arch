# Pages, wrappers and dumb widgets

Blocs and cubits: `blocs.md`. Widget shape: `widget_rules.md`.

| Role | Folder | Does | flutter_bloc | Use cases |
|---|---|---|---|---|
| page | `pages/` | creates the blocs (`BlocProvider`), passes their methods down as callbacks, reacts (`BlocListener`), holds the texts | `BlocProvider`, `BlocListener`, `context.read` — never rebuilds | through the blocs it creates |
| wrapper | `wrappers/` | selects what one dumb widget shows and passes it | `BlocSelector` / `context.select` | none |
| dumb widget | `widgets/` | draws data, calls callbacks | none | none |

```
NotesPage → _NotesViewWidget    BlocProviders, BlocListener (snackbars), texts, cubit methods as callbacks
├─ AddNoteWrapper               BlocSelector<NoteActionsCubit, …, bool>(isRunning); owns the field's controller
│   └─ AddNoteWidget(noteTextController, isAdding, hintText, addLabel, onAddPressed)
└─ NotesListWrapper             BlocSelector<NotesBloc, …, _NotesListContent>(ids)
    └─ NotesListWidget(isLoading, failureText, emptyText, noteIds, itemBuilder)
        └─ NoteTileWrapper(id)  BlocSelector<NotesBloc, …, Note?>(the note with this id)
            └─ NoteTileWidget(note, deleteTooltip, onTap, onDeletePressed)
```

Code: `example/lib/features/notes/presentation/` (`pages/notes_page.dart`, `wrappers/`, `widgets/`) and
`example/lib/features/statistics/presentation/` (a wrapper per number).

## Dumb widgets — `presentation/widgets/`

- Take data and callbacks; draw; call the callbacks. Nothing of the app: no state manager, DI, getters, use cases,
  controllers, blocs, translations, wrappers or other layers (linter: `widgets_dumb`). They may take the entities of
  their feature (`Note`).
- `StatelessWidget`; a `StatefulWidget` only to own a plain Flutter controller (`TextEditingController`,
  `AnimationController`) created in `initState` and disposed in `dispose` — `edit_note_dialog_widget.dart`.
- Texts come as parameters, already translated; a failure arrives as its text. Then the widget moves to
  `lib/core/presentation/widgets/` unchanged when a second feature needs it.
- The dumb widgets of every template are the same files: `example/lib/features/notes/presentation/widgets/`.

### Parameter names — as in Flutter

| Kind | Name | Examples |
|---|---|---|
| texts | what the text is, like Flutter's `hintText`, `labelText`, `tooltip` | `hintText`, `emptyText`, `failureText`, `deleteTooltip` |
| button labels | `<action>Label` | `addLabel`, `saveLabel`, `cancelLabel` |
| flags | `is` / `has` / `can` + what | `isAdding`, `isLoading`, `isPinned`, `hasFailed` |
| callbacks | Flutter's event names | `onTap`, `onChanged`, `onSubmitted`, `on<Thing>Pressed` (`onAddPressed`, `onDeletePressed`) |
| data | a noun | `note`, `noteIds`, `value` |
| a builder | `<thing>Builder` | `itemBuilder` |
| a Flutter controller | `<noun>Controller` (linter: `controller_naming`) | `noteTextController` |

More than about four texts → one object `<Widget>Texts` with the same field names (`EditNoteDialogTexts(titleText:
…, cancelLabel: …, saveLabel: …)`).

## Wrappers — `presentation/wrappers/`

A wrapper selects from the state exactly what one dumb widget shows and passes it with the texts and the callbacks
from the page. It rebuilds only when that part changes.

- **When a wrapper is needed:** when a selection updates exactly this part of the screen and not its neighbours (the
  add button: `isAdding`; one note: its `Note`; one number of the statistics). A part with no selection of its own is
  placed by the page directly. One wrapper per part that changes on its own — not one per widget.
- **Names:** `<Thing>Wrapper` for `<Thing>Widget`, file `<thing>_wrapper.dart` (linter: `naming_class`,
  `naming_file`).
- **What it selects** is comparable by value: a `bool`, a number, a `String`, an enum, an entity with `==`
  (`Note`), or a small private value class with `==` (`_NotesListContent` with `listEquals` on the ids). Never a new
  `List` or a `.where(…)` result: it differs on every call and the wrapper rebuilds every time.
- It turns a failure into its text (`failure.text` from `presentation/l10n`) — the widget gets a `String`.
- **It starts nothing:** no action use case, no `context.read<…>()` of a cubit — the page passes those as callbacks
  (linter: `wrappers_no_actions`). Watch use cases (`watchNotesUseCase()`) are its job.
- It may own a plain Flutter controller when the page has none (bloc: `AddNoteWrapper` owns the field's controller).

## Pages — `presentation/pages/`

The page is the smart one: it owns the UI controller or creates the blocs, starts the actions, reacts to their
outcome (snackbars, dialogs, navigation) and holds the texts. It places wrappers and dumb widgets and **never
rebuilds itself**.

## Lists

- `ListView.builder`; every item is a wrapper with `key: ValueKey<String>(id)`.
- The list wrapper selects the ids (loading and failure too) — a change inside one item does not rebuild it; the
  item wrapper selects its item by id — so an edited note rebuilds one tile.
- When the ids change (an item added, deleted, moved) the list rebuilds and Flutter rebuilds its visible items too —
  the keys keep their elements and state; that is cheap and expected.

## Rebuilds are tested

`example/test/rebuilds_test.dart` counts the builds of every widget type with `debugOnRebuildDirtyWidget`: an edited
note rebuilds one `NoteTileWidget` and no `NotesListWidget`; a changed number rebuilds only its `StatisticTileWidget`.
Add such a test for every screen whose rebuilds matter — otherwise a selector that returns a new list breaks the
rule silently.

## Small things that keep rebuilds away

- `const` constructors on dumb widgets and wrappers; `const` lists of children where possible.
- Pass methods as callbacks (`noteActionsCubit.add`, `_onPinPressed`) instead of new closures where the signature
  fits.
