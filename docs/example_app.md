# The example app

Every template's `example/` builds this same program, so templates can be compared file by file. Only the
architecture differs (state manager, DI, how state reaches widgets); the behavior, texts and tests are the same.

## What it does

A notes app with two tabs (a `NavigationBar` over an `IndexedStack`, both tabs stay alive):

- **Notes** — a text field with an "Add" button, the notes newest first, each with a "Delete" button; tapping a note
  opens an "Edit note" dialog (Cancel / Save). Blank text is refused with "Note text must not be empty". Failures show
  as a snackbar; a failed add keeps the typed text. While loading: a progress indicator; empty: "No notes yet"; a load
  error replaces the list.
- **Statistics** — live numbers over the same notes: notes, words, added today, edited (a note whose `updatedAt` is
  not its `createdAt`).

## Where the data lives

There is no real database: `lib/core/data/data_sources/` has an `AppDatabase` interface and `InMemoryAppDatabase`, a
placeholder that behaves like one:

- tables of rows (`Map<String, Object?>`, keyed by `id`), `watchTable(table)` emits the rows right away and after every
  change (`Stream.multi`, so no change is lost), `insert` / `update` / `delete`, `close()`;
- every call waits `latency` (default 120 ms) like I/O; tests pass `Duration.zero`;
- an unknown id in `update` / `delete` throws, like a database.

Both features read the same `notes` table through their own data sources, models and repositories — features never
import each other:

| Feature | Data source | Model | Entity | Use cases |
|---|---|---|---|---|
| `notes` | `DatabaseNotesDataSource` (UUID v4 ids, `createdAt` / `updatedAt` from an injected clock) | `NoteModel` (row ↔ model ↔ `Note`) | `Note` (id, text, createdAt, updatedAt) | `WatchNotes`, `AddNote`, `UpdateNote` (both trim and refuse blank text), `DeleteNote` |
| `statistics` | `DatabaseStatisticsDataSource` (reads the `notes` table) | `NoteFactsModel` | `NoteFacts`, `NotesStatistics.of(facts, now:)` | `WatchNotesStatistics` |

`lib/core/` also holds `Result`, the shared `AppTheme`, the core DI (logger, database) and the home page with the tabs.

## Tests (every template)

- domain: `AddNoteUseCase` / `UpdateNoteUseCase` validation with a fake repository; `NotesStatistics.of` counts;
- data: `InMemoryAppDatabase` (emits, unknown id throws); notes repository (stream, failures); statistics repository;
- presentation: the template's state holders (controllers or blocs); the notes page flow (add, edit, delete, blank,
  failed add, load error); the statistics page; switching tabs.

Texts used by the tests: `Notes`, `Statistics`, `Add`, `New note`, `No notes yet`, `Delete`, `Edit note`, `Save`,
`Cancel`, `Note text must not be empty`, `Could not add the note`, `Could not load the notes`, `Could not load the
statistics`, and the statistic labels `Notes`, `Words`, `Added today`, `Edited`.
