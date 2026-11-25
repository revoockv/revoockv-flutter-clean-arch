# One feature uses another

A feature may use another one — the example's notes use the pins (a deleted note loses its pin, every note shows
the pin button), and the statistics count the notes and the pins. How:

| Layer | What it may use of another feature | Example |
|---|---|---|
| domain | its entities and repository interfaces; a use case may work with the repositories of two features | `DeleteNoteUseCase(NotesRepository, PinsRepository)` deletes a note and unpins it |
| data | a repository may build on the **repository interfaces** of other features instead of their tables | `StatisticsRepositoryImpl(notes: NotesRepository, pins: PinsRepository)` — the statistics have no data source of their own |
| presentation | its wrappers and dumb widgets (placed by the page into a slot), its blocs and cubits (the page creates them), its use case getters and its failure texts | the notes page fills `NoteTileWidget(leading: …)` with the pins' `PinButtonWrapper` |

Never: its `data/` (data sources, models, repository implementations), its controllers, its DI registration. Its
storage is its own business — a feature that reads another's table breaks when that table changes.

## The direction is one way

Draw the features and their arrows before writing the code; the arrows never close a circle:

```
pins ◄── notes ◄── statistics
  ▲                    │
  └────────────────────┘
```

A feature that is used knows nothing about its users (pins know no notes). When two features seem to need each
other, the shared part moves into the one both use, or into `core`. The linter rule `feature_dependencies` reports an
import of another feature's data, controllers or DI and an import that closes a circle.

## Wiring

- `AppProvidersWidget` nests the providers so a feature sits **below** the features it uses:
  `CoreProvidersWidget` → `PinsProvidersWidget` → `NotesProvidersWidget` → `StatisticsProvidersWidget`.
- A repository or use case reads the other feature's repository from the tree: `DeleteNoteUseCase(
  context.read<NotesRepository>(), context.read<PinsRepository>())`.
- The page that shows another feature's wrapper also creates that feature's blocs (`PinsBloc`, `PinActionsCubit`)
  with `BlocProvider` and passes their methods down (`onPressed: pinActionsCubit.toggle`).

## Entities stay small

A feature takes from another only what it needs and maps it into its own entity: the statistics turn a `Note` and the
`PinnedNotes` into `NoteFacts(text, createdAt, updatedAt, isPinned)` — no id, nothing else. Its entity changes only
when the statistics need something new, not when a note gets a new field.
