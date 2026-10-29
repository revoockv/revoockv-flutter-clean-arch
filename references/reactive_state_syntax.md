# Reactive state syntax (required)

Packages:
- `get_it`
- `watch_it`

## The contract: ValueNotifier inside, ValueListenable outside

- The repository implementation owns a **private** `ValueNotifier<T>` and is the only place that writes `.value`.
- A repository that mirrors a stream exposes `ValueListenable<ResultState<T>>`: `loading` until the first event, `success(value)` on every event, `failure(message)` on a stream error — never a bare `List<T>` that cannot tell "loading" and "could not load" from "empty" (`references/result_state.md`).
- Everything outward — repository interface, watch use case, getter — is typed `ValueListenable<T>`. The UI cannot assign `.value`, so state changes only through action use cases (`Future<Result>`).
- A watch use case `call()` must return the **same instance** every time (the repository field). Never build a new listenable per call.

## Repository

```dart
import 'package:flutter/foundation.dart' show ValueListenable;

abstract interface class SongRepository {
  /// Returns the live list of songs: loading, the songs, or the load failure.
  ValueListenable<ResultState<List<Song>>> watchSongs();
}
```

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

final class SongRepositoryImpl implements SongRepository, DisposableResource {
  /// Message shown when the songs cannot be loaded.
  static const String _loadFailedMessage = 'Could not load the songs';

  static const String _initLog = 'SongRepository init: subscribed to songs';
  static const String _disposeLog = 'SongRepository dispose: unsubscribed';
  static const String _watchFailureLog = 'WatchSongs: failure — ';

  final SongDataSource _dataSource;

  final Logger _logger;

  /// Source of truth — written only by this repository; loading until the first event.
  final ValueNotifier<ResultState<List<Song>>> _songs =
      ValueNotifier<ResultState<List<Song>>>(ResultState.loading);

  StreamSubscription<List<SongModel>>? _sub;

  SongRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to the data source and mirrors it into [_songs]; returns this for DI.
  Future<SongRepositoryImpl> init() async {
    _sub ??= _dataSource.watchSongs().listen(_onSongs, onError: _onError);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases [_songs]. Called by DI only.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _songs.dispose();
    _logger.i(_disposeLog);
  }

  void _onSongs(List<SongModel> models) {
    _songs.value = ResultState.success(models.map(_toEntity).toList());
  }

  void _onError(Object error) {
    _logger.e('$_watchFailureLog$error');
    _songs.value = const ResultState.failure(_loadFailedMessage);
  }

  Song _toEntity(SongModel model) => model.toEntity();

  @override
  ValueListenable<ResultState<List<Song>>> watchSongs() => _songs;
}
```

## Watch use case

```dart
import 'package:flutter/foundation.dart' show ValueListenable;

final class WatchSongsUseCase {
  final SongRepository _repository;

  WatchSongsUseCase(this._repository);

  /// Returns the live list of songs; the same instance on every call.
  ValueListenable<ResultState<List<Song>>> call() => _repository.watchSongs();
}
```

## Getter

`<feature>_getters.dart` exposes the **use case object** as a top-level getter:

```dart
/// Watch use case for the live list of songs.
WatchSongsUseCase get watchSongsUseCase => di<WatchSongsUseCase>();
```

- `watchSongsUseCase` (no parentheses) — the use case object.
- `watchSongsUseCase()` (with parentheses) — invokes `call()` and returns the `ValueListenable`.

## Derived state

A value computed from other state (e.g. `isSignedIn` from `AuthState`) is one more private `ValueNotifier` in the same repository, updated together with its source and exposed through its own watch use case:

```dart
final ValueNotifier<AuthState> _state = ValueNotifier<AuthState>(const UnknownAuthState());
final ValueNotifier<bool> _isSignedIn = ValueNotifier<bool>(false);

void _setState(AuthState state) {
  _state.value = state;
  _isSignedIn.value = state is SignedInAuthState;
}

@override
ValueListenable<bool> watchIsSignedIn() => _isSignedIn;
```

A widget that needs only `isSignedIn` watches `watchIsSignedInUseCase()` and does not rebuild on other `AuthState` changes. Never register state in GetIt (`instanceName`, `registerSingleton<ValueNotifier<…>>`) — linter: `no_state_in_di`.

## Flutter UI (the only canonical form)

```dart
import 'package:flutter/widgets.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/song.dart';
import '../di/song_getters.dart';
import 'song_tile_widget.dart';

/// Shows the live list of songs.
final class SongListWidget extends WatchingWidget {
  const SongListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ResultState<List<Song>> songs = watch(watchSongsUseCase()).value;

    return switch (songs) {
      IdleResultState<List<Song>>() || LoadingResultState<List<Song>>() => const SizedBox.shrink(),
      FailureResultState<List<Song>>(:final String message) => Text(message),
      SuccessResultState<List<Song>>(:final List<Song> value) => ListView(
          children: <Widget>[
            for (final Song song in value) SongTileWidget(song: song),
          ],
        ),
    };
  }
}
```

`watch(listenable)` subscribes the widget and returns the **listenable itself**, so `.value` is required right after it.

## Reacting to state: `registerHandler`

`watch()` **shows** state — it rebuilds the widget. One-off reactions — navigation, snackbar, dialog — never go into `build()` (it runs many times, and navigating during build throws). They go into `registerHandler` from watch_it: it is called in `build()`, but its handler runs **once per value change** and does not rebuild the widget.

```dart
// NotesPage — the owner of a controller only reacts, it never rebuilds
final NotesController controller = createOnce(_createController, dispose: _disposeController);
registerHandler(target: controller, handler: _onActionChanged);

void _onActionChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
  if (state is! FailureResultState<void>) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
}
```

- `target:` takes the listenable directly — nothing extra goes into GetIt.
- The handler is a private method `(BuildContext context, T value, void Function() cancel)`: no inline closure, `context` arrives as a parameter, `value` is fully typed. `cancel()` unsubscribes from inside the handler.
- The same works for a UI controller: `registerHandler(target: controller, handler: _onActionChanged)` — see `references/controllers.md`.
- `registerHandler` does not rebuild: put it as high as the reaction needs (the page), and `watch()` as low as possible (the widget that shows the value).
- **The handler runs only on a change**, not for the value at the first build. When the current value must trigger the reaction too, pass `executeImmediately: true`.
- **Which screen to show is not a reaction.** "Signed out → sign-in screen" is a `watch` + `switch` over the state that picks the widget (`AuthGateWidget` in `references/feature_template_auth.md`) — no navigation, no routes, and the first state counts.

## The order rule

watch_it binds every `watch()` and `registerHandler()` call to its **position** in `build()` (like React hooks). Call them unconditionally at the top of `build()`, then branch on the values:

```dart
// ❌ the position of the second watch changes between builds
final AuthState state = watch(watchAuthStateUseCase()).value;
if (state is SignedInAuthState) {
  final ResultState<List<Song>> songs = watch(watchSongsUseCase()).value;
}

// ✅ every watch on every build; conditions use the values
final AuthState state = watch(watchAuthStateUseCase()).value;
final ResultState<List<Song>> songs = watch(watchSongsUseCase()).value;
if (state is! SignedInAuthState) return const SignInButtonWidget();
```

An early `return` is fine — the calls before it keep their positions. Never call them inside `if` / `for` / `switch` blocks or inside builder callbacks (linter: `watch_order`).

## Hard rules

- UI reads state only as `watch(watch<Name>UseCase()).value` inside a `WatchingWidget` / `WatchingStatefulWidget`.
- One-off reactions to state (snackbar, dialog, navigation to a detail route) use `registerHandler(target: …, handler: _onX)` — never `build()` logic. Which screen a state needs is a `watch` + `switch`, not a reaction.
- `watch()` / `registerHandler()` run unconditionally at the top of `build()` (linter: `watch_order`).
- `watchValue()` and `watchIt()` are not used in presentation widgets (linter: `watching_widget`).
- `ValueNotifier` never appears in domain, in public repository members, or in getters (linter: `value_listenable_exposure`).
- Use `ValueNotifier` / `ValueListenable` as feature state (NOT Signals/Computed).
