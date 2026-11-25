# The example app

Every template's `example/` builds this same program, so templates can be compared file by file. Only the
architecture differs (state manager, DI, how state reaches widgets); the behavior, texts and tests are the same.

## What it does

A notes app with two tabs (a `NavigationBar` over an `IndexedStack`, both tabs stay alive):

- **Notes** — a text field with an "Add" button, the notes newest first, each with a "Delete" button; tapping a note
  opens an "Edit note" dialog (Cancel / Save). Blank text is refused with "Note text must not be empty". Failures show
  as a snackbar; a failed add keeps the typed text. While loading: a progress indicator; empty: "No notes yet"; a load
  error replaces the list. Every note has a pin button ("Pin" / "Unpin"); deleting a note drops its pin; a failed pin
  shows "Could not pin the note".
- **Statistics** — live numbers over the same notes: notes, words, added today, edited (a note whose `updatedAt` is
  not its `createdAt`), pinned.

## Where the data lives

There is no real database: `lib/core/data/data_sources/` has an `AppDatabase` interface and `InMemoryAppDatabase`, a
placeholder that behaves like one:

- tables of rows (`Map<String, Object?>`, keyed by `id`), `watchTable(table)` emits the rows right away and after every
  change (`Stream.multi`, so no change is lost), `insert` / `update` / `delete`, `close()`;
- every call waits `latency` (default 120 ms) like I/O; tests pass `Duration.zero`;
- an unknown id in `update` / `delete` throws, like a database.

Three features; one uses another through its domain and its UI parts, never its data, and the arrows never close a
circle (`rules/structure/feature_dependencies.md`): **notes → pins**, **statistics → notes, pins**.

| Feature | Data source | Model | Entity | Use cases | Uses |
|---|---|---|---|---|---|
| `pins` | `DatabasePinsDataSource` (the `pins` table, a row per pinned note id) | `PinModel` | `PinnedNotes` (compared by value), `PinFailure` | `WatchPinnedNotes`, `TogglePin` | — |
| `notes` | `DatabaseNotesDataSource` (UUID v4 ids, `createdAt` / `updatedAt` from an injected clock) | `NoteModel` (row ↔ model ↔ `Note`) | `Note` (id, text, createdAt, updatedAt) | `WatchNotes`, `AddNote`, `UpdateNote` (both trim and refuse blank text), `DeleteNote` (unpins the deleted note) | pins: `PinsRepository` in `DeleteNoteUseCase`, `PinButtonWrapper` in every note |
| `statistics` | none | none | `NoteFacts` (text, createdAt, updatedAt, isPinned), `NotesStatistics.of(facts, now:)` | `WatchNotesStatistics` | notes and pins: its repository counts `NotesRepository` and `PinsRepository` |

`lib/core/` also holds `Result`, the shared `AppTheme`, the core DI (logger, database) and the home page with the tabs.

## Tests (every template)

- domain: `AddNoteUseCase` / `UpdateNoteUseCase` validation with a fake repository; `NotesStatistics.of` counts;
- data: `InMemoryAppDatabase` (emits, unknown id throws); notes repository (stream, failures); statistics repository;
- presentation: the template's state holders (controllers or blocs); the notes page flow (add, edit, delete, blank,
  failed add, load error); the statistics page; switching tabs;
- pins: the repository (toggle, unpin), `DeleteNoteUseCase` unpins a deleted note (fake repositories), the pin
  button on the notes page; statistics count notes and pins through their repositories;
- rebuilds (`test/rebuilds_test.dart`, `debugOnRebuildDirtyWidget`): an edited note rebuilds one `NoteTileWidget` and
  no `NotesListWidget`; a new note rebuilds the list; a pin rebuilds only its `PinButtonWidget`; a changed number
  rebuilds only its `StatisticTileWidget`.

## Screens are built the same way (every template)

Pages start the actions and react; wrappers select from the state exactly what one dumb widget shows; the dumb
widgets (`presentation/widgets/`) are **the same files in every template** — only pages and wrappers differ:
`AddNoteWrapper` (adding or not), `NotesListWrapper` (the ids), `NoteTileWrapper` (one note by id),
`StatisticsListWrapper` (loading or failed), `StatisticTileWrapper` (one number).

Texts used by the tests: `Notes`, `Statistics`, `Add`, `New note`, `No notes yet`, `Delete`, `Edit note`, `Save`,
`Cancel`, `Pin`, `Unpin`, `Note text must not be empty`, `Could not add the note`, `Could not load the notes`,
`Could not load the statistics`, `Could not pin the note`, and the statistic labels `Notes`, `Words`, `Added today`,
`Edited`, `Pinned`.
