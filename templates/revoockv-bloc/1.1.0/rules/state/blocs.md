# Blocs and cubits

Example: `example/lib/features/notes/presentation/blocs/`.

## Which one

- **Bloc** (`on<Event>`) for live data that follows a stream: `NotesBloc` subscribes on `NotesSubscribed` with
  `emit.forEach(watchNotesUseCase(), onData: _toState)`.
- **Cubit** (methods) for actions and UI state: `NoteActionsCubit.add(text)` / `.delete(id)`; its state is the progress
  of the last action (`Idle`, `Running`, `Done(action)`, `Failed(message)`).
- One bloc per thing that changes on its own; a screen may have several.

## Rules

- Blocs and cubits are the only callers of use cases; they get them as private named constructor parameters
  (`NotesBloc({required this._watchNotesUseCase})`). They never touch data sources or repositories.
- States and events are `sealed` classes with `final` subclasses; a state that carries data writes `==` and `hashCode`
  by hand (`listEquals` for lists) so `emit` skips equal states and `bloc_test` can compare them. No `equatable`.
- Name events by what happened (`NotesSubscribed`, `NoteDeleteRequested`), states by what is shown (`NotesLoading`,
  `NotesLoaded`, `NotesLoadFailed`).
- A failure is a state with a human-readable message (from `Result.failure`), never a thrown error.
- One action at a time: a cubit method returns early while `state.isRunning`; after an `await` it checks `isClosed`
  before `emit`.
- Streams end in blocs: no `StreamSubscription` in widgets.

## Widgets and state

| Need | Use |
|---|---|
| Show the whole state | `context.watch<NotesBloc>().state` + `switch` over the sealed state |
| Rebuild for one part only | `context.select<NoteActionsCubit, bool>(_isRunning)` in the lowest widget that shows it |
| Snackbar, dialog, navigation, clearing a field | `BlocListener(listenWhen: _isFailure, listener: _onActionFailed)` — never in `build()` |
| Send an action | `context.read<NoteActionsCubit>().add(text)` / `context.read<NotesBloc>().add(event)` in a private method |

- `listenWhen`, `listener`, `selector` and `create` are private methods (static when they need no instance).
- `watch` / `select` only in `build()`; `read` only in callbacks and `create`.
