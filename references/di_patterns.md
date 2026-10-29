# DI patterns (GetIt via `di` + ValueListenable + watch_it)

Must follow:
- `references/reactive_state_syntax.md`
- `references/models_mapping.md`
- `references/controllers.md`

## Files

| File | Exposes |
|---|---|
| `lib/di.dart` | `registerAndInit()` — the only DI call in `main.dart` |
| `lib/core/presentation/di/core_di.dart` | `registerAndInitCore()`, `disposeResource()` |
| `lib/features/<feature>/presentation/di/<feature>_di.dart` | `registerAndInit<Feature>()` |
| `lib/features/<feature>/presentation/di/<feature>_getters.dart` | one top-level getter per use case |

## Rules

1. **Use `di`.** watch_it exports get_it and provides the global `di` (= `GetIt.I`). Import `package:watch_it/watch_it.dart` and write `di<T>()`, `di.registerLazySingleton(...)`. Never `GetIt.instance`, `GetIt.I` or a local `getIt` variable.
2. **Register by type.** No `instanceName`, no `ValueNotifier` / `ValueListenable` in GetIt — state lives in repositories (linter: `no_state_in_di`).
3. **Register bottom-up:** data sources / services → repositories → use cases.
4. **Lazy wherever possible.** `registerLazySingleton` for data sources, use cases and repositories without startup work — created on first access.
5. **Async init in the class.** A class that needs startup work (subscriptions, opening a DB, SDK init) has `Future<Impl> init()` that returns `this`, and is registered with `registerSingletonAsync(() => Impl(...).init())`. Its `init()` starts right away; `registerAndInit()` waits for all of them with `di.allReady()`, so slow inits of different features run in parallel.
6. **Dependency on another feature's async singleton:** add `dependsOn: [OtherRepository]`, so the factory runs only after that singleton is ready.
7. **Every class that owns resources** implements `DisposableResource` (our interface, no get_it in data) and is registered with `dispose: disposeResource`. See "Dispose" below.
8. Logger and all other dependencies go through constructors — classes never call `di` themselves.

## Core

`lib/core/domain/entities/disposable_resource.dart`

```dart
import 'dart:async';

/// A class that owns resources (subscriptions, controllers, connections) and must release them.
abstract interface class DisposableResource {
  /// Releases every resource the class owns. Called by DI, never by UI or use cases.
  FutureOr<void> dispose();
}
```

`lib/core/presentation/di/core_di.dart`

```dart
import 'dart:async';

import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/disposable_resource.dart';

/// GetIt `dispose:` callback: calls our [DisposableResource.dispose] if [instance] owns resources.
FutureOr<void> disposeResource(Object instance) =>
    instance is DisposableResource ? instance.dispose() : null;

/// Registers app-wide services used by every feature.
void registerAndInitCore() {
  di.registerSingleton<Logger>(Logger());
}
```

`disposeResource` is the only place where DI meets our dispose contract: dropping get_it later means rewriting DI files only — data and domain stay untouched.

## Feature: `registerAndInit<Feature>()`

`lib/features/auth/presentation/di/auth_di.dart`

```dart
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/auth_data_source.dart';
import '../../data/data_sources/auth_data_source_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/watch_auth_state_use_case.dart';

/// Registers the auth feature and starts its async initialization.
///
/// Plug the feature into any app with this single call; `di.allReady()` waits for its `init()`.
void registerAndInitAuth() {
  // 1. data sources
  di.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(),
    dispose: disposeResource,
  );

  // 2. repositories — async init: subscribes to the data source
  di.registerSingletonAsync<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: di<AuthDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchAuthStateUseCase>(() => WatchAuthStateUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignInUseCase>(() => SignInUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(di<AuthRepository>()));
}
```

A feature without startup work registers everything lazily — the function name stays `registerAndInit<Feature>()`.

Dependency on another feature (`lib/features/backup/presentation/di/backup_di.dart`):

```dart
/// Registers the backup feature; waits for the song repository to be ready.
void registerAndInitBackup() {
  di.registerSingletonAsync<BackupRepository>(
    () => BackupRepositoryImpl(songRepository: di<SongRepository>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[SongRepository],
    dispose: disposeResource,
  );
  di.registerLazySingleton<BackupSongsUseCase>(() => BackupSongsUseCase(di<BackupRepository>()));
}
```

## Repository with init and dispose

```dart
final class AuthRepositoryImpl implements AuthRepository, DisposableResource {
  static const String _initLog = 'AuthRepository init: subscribed to user changes';
  static const String _disposeLog = 'AuthRepository dispose: unsubscribed';

  final AuthDataSource _dataSource;

  final Logger _logger;

  final ValueNotifier<AuthState> _state = ValueNotifier<AuthState>(const UnknownAuthState());

  StreamSubscription<AuthUserModel?>? _sub;

  AuthRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to the data source; returns this for `registerSingletonAsync`.
  Future<AuthRepositoryImpl> init() async {
    _sub ??= _dataSource.watchUser().listen(_onUser);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _state.dispose();
    _logger.i(_disposeLog);
  }

  // watchAuthState(), signIn(), signOut(), _onUser() — see references/feature_template_auth.md
}
```

`init()` is called on the implementation before it is exposed as `AuthRepository`, so the domain interface needs neither `init()` nor `dispose()`.

## App: `registerAndInit()`

`lib/di.dart`

```dart
/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();

  registerAndInitAuth();
  registerAndInitSong();
  registerAndInitBackup();

  await di.allReady();
}
```

`main.dart` calls only `registerAndInit()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await registerAndInit();

  runApp(const App());
}
```

## Dispose — what and when

**Implement `DisposableResource` in every class that owns:**
- `StreamSubscription`, `StreamController`, `Timer`
- the repository's private `ValueNotifier`s
- connections: sockets, databases, platform/SDK listeners

**`dispose()` must:** cancel subscriptions and timers, close controllers and connections, dispose `ValueNotifier`s — in reverse order of creation, and log it. It is never called manually from UI, use cases or other repositories: GetIt calls it through `disposeResource`.

**GetIt disposes when:**

| Moment | How | Why |
|---|---|---|
| Tests | each test registers a test DI of its feature (fake data sources) and `await di.reset()` in `tearDown` | Every test starts clean, no leaked subscriptions, no real backend — `references/testing.md` |
| App start | `await di.reset()` at the top of `registerAndInit()` | Safe re-initialization |
| Desktop exit (optional) | `await di.reset()` from `AppLifecycleListener.onExitRequested` | Close a DB / files cleanly |

On mobile, app close needs nothing — the OS kills the process. App-wide services (Logger, HTTP client) are not disposed separately.

**UI-level controllers** (UI controllers, `TextEditingController`, `ScrollController`, `AnimationController`) are not in GetIt. Their owner disposes them: a `WatchingWidget` through `createOnce(…, dispose: …)`, a UI controller in its own `dispose()`, an `AnimationController` in `State.dispose()` — see `references/controllers.md` → "Owner and rebuilds".
