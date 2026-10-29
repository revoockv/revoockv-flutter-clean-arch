# Reactive state patterns (minimal rebuilds)

Syntax and the full contract: `references/reactive_state_syntax.md`.

## One source, read-only outward

- The repository owns a private `ValueNotifier<T>`; everything outward is `ValueListenable<T>`.
- Split state into several listenables when parts change independently (e.g., `watchSongs()` and `watchIsSyncing()`), so each widget rebuilds only for what it reads.

## Watch placement

- Keep `WatchingWidget` low in the widget tree — at the smallest widget that must rebuild.
- Split UI into small `StatelessWidget`s; pass watched values down as constructor parameters.
- Each `WatchingWidget` reads only what its subtree needs: `watch(watch<Name>UseCase()).value`, `watch(controller).value.isLoading`.
- The state of one thing is one value — a sealed class, an enum, `ResultState` — not several notifiers that always change together.
- A widget that only reacts (`registerHandler`) never rebuilds; the owner of a controller usually only reacts and passes the controller down as `ValueListenable<S>`.
- All `watch()` / `registerHandler()` / `createOnce()` calls go unconditionally at the top of `build()` (the order rule).

## Side effects

| Trigger | Where the reaction lives |
|---|---|
| Domain state changes by itself (sync failed) | `registerHandler(target: watch<Name>UseCase(), handler: _onX)` in the widget that owns that screen area (`executeImmediately: true` when the first value counts) |
| The state needs another screen (signed out → sign-in) | not a reaction: `watch` + `switch` in a gate widget picks the screen (`AuthGateWidget`) |
| User action returns `Result` (sign-in failed) | The controller sets `ResultState.failure(message)`; its owner reacts with `registerHandler(target: controller, handler: _onActionChanged)` |
| One-time startup work | `init()` of the repository, run by `registerAndInit()` |

Never put navigation, snackbars or dialogs directly into `build()`.
