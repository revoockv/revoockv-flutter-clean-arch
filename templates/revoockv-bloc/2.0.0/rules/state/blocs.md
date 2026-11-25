# Blocs and cubits

Example: `example/lib/features/notes/presentation/blocs/`.

## Which one

- **Bloc** (`on<Event>`) for live data that follows a stream: `NotesBloc` subscribes on `NotesSubscribed` with
  `emit.forEach(watchNotesUseCase(), onData: _toState)`.
- **Cubit** (methods) for actions and UI state: `NoteActionsCubit.add(text)` / `.delete(id)`; its state is the progress
  of the last action (`Idle`, `Running`, `Done(action)`, `Failed(failure)`).
- One bloc per thing that changes on its own; a screen may have several.

## Rules

- Blocs and cubits are the only callers of use cases; they get them as private named constructor parameters
  (`NotesBloc({required this._watchNotesUseCase})`). They never touch data sources or repositories.
- States and events are `sealed` classes with `final` subclasses; a state that carries data writes `==` and `hashCode`
  by hand (`listEquals` for lists) so `emit` skips equal states and `bloc_test` can compare them. No `equatable`.
- Name events by what happened (`NotesSubscribed`, `NoteDeleteRequested`), states by what is shown (`NotesLoading`,
  `NotesLoaded`, `NotesLoadFailed`).
- A failure is a state that carries the failure of the feature (from `Result.failure`), never a thrown error and never a ready text: the page or widget turns it into text with the extension in `presentation/l10n` (`state.failure.text`).
- One action at a time: a cubit method returns early while `state.isRunning`; after an `await` it checks `isClosed`
  before `emit`.
- Streams end in blocs: no `StreamSubscription` in widgets.

## Widgets and state

Pages, wrappers and dumb widgets: `wrappers.md`.

| Need | Where | Use |
|---|---|---|
| Show one part of a state | a wrapper | `BlocSelector<NotesBloc, NotesState, Note?>(selector: _noteOf, …)` or `context.select<StatisticsBloc, bool>(_isLoadingOf)` |
| Show the whole state | a wrapper, only when the widget shows all of it | `context.watch<NotesBloc>().state` + `switch` |
| Snackbar, dialog, navigation, clearing a field | the page (or the wrapper that owns the field) | `BlocListener(listenWhen: _isFailure, listener: _onActionFailed)` — never in `build()` |
| Send an action | the page | pass the method down: `onAddPressed: noteActionsCubit.add` |

- `listenWhen`, `listener`, `selector` and `create` are private methods (static when they need no instance).
- `watch` / `select` only in wrappers' `build()`; `read` only in pages (callbacks, `create`).
