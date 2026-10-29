# Auth feature template (Clean Architecture + GetIt + ValueNotifier + watch_it)

Packages (the pinned versions live in `assets/example_app/pubspec.yaml`; `scripts/check_versions.py` compares them with pub.dev):

```yaml
environment:
  sdk: ^3.12.0

dependencies:
  get_it: ^9.3.0
  logger: ^2.8.0
  uuid: ^4.6.0
  watch_it: ^2.5.0

dev_dependencies:
  flutter_lints: ^6.0.0
```

A complete, runnable app built with these rules (neutral notes feature, tests included): `assets/example_app/`.

This template is the golden path. When uncertain, copy it and rename only.

It enforces:

- Controllers only when there is UI logic (a plain class with notifiers, or a `ValueNotifier` itself); they never touch the data layer.
- DataSource may use Streams; repository owns a private ValueNotifier and exposes ValueListenable.
- Models (DTO) convert to/from Domain entities in the model class.
- UI reads state only as `watch(watch<Name>UseCase()).value` via top-level getters.
- Which screen to show is a `watch` + `switch` over the state (`AuthGateWidget`); one-off reactions (snackbars) go through `registerHandler(target: …, handler: _onX)`.
- An action whose progress or error the UI shows goes through a UI controller (one `ResultState`; the widget shows a failure with `registerHandler`); an action with nothing to show is called by the widget directly.
- Result is used for success/failure.
- Use cases pass through repository Result — no try/catch in use cases.

---

## Core

Create (copy from `assets/example_app/lib/core/`, or run `scripts/init_feature.py --core`):
- `lib/core/domain/entities/result.dart` — `references/result.md`
- `lib/core/domain/entities/disposable_resource.dart` and `lib/core/presentation/di/core_di.dart` — `references/di_patterns.md`
- `lib/core/presentation/theme.dart` — values shared by several features (`SKILL.md` → "Constants")

Use import (replace `your_app` with your package name):
- `import 'package:your_app/core/domain/entities/result.dart';`

---

## Domain: entities

`lib/features/auth/domain/entities/auth_user.dart`

```dart
/// Signed-in user.
final class AuthUser {
  /// Unique id of the user.
  final String id;

  /// Creates a user.
  const AuthUser({required this.id});
}
```

`lib/features/auth/domain/entities/auth_state.dart`

```dart
import 'auth_user.dart';

/// Sign-in state of the app.
sealed class AuthState {
  /// Creates a state.
  const AuthState();
}

/// The state is not known yet (before the first event of the data source).
final class UnknownAuthState extends AuthState {
  /// Creates the state.
  const UnknownAuthState();
}

/// Nobody is signed in.
final class SignedOutAuthState extends AuthState {
  /// Creates the state.
  const SignedOutAuthState();
}

/// [user] is signed in.
final class SignedInAuthState extends AuthState {
  /// The signed-in user.
  final AuthUser user;

  /// Creates the state.
  const SignedInAuthState({required this.user});
}

/// The state could not be loaded.
final class FailureAuthState extends AuthState {
  /// Human-readable message for the UI.
  final String message;

  /// Creates the state.
  const FailureAuthState({required this.message});
}
```

---

## Domain: repository interface

`lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:your_app/core/domain/entities/result.dart';

import '../entities/auth_state.dart';

/// Source of truth for the sign-in state.
abstract interface class AuthRepository {
  /// Live sign-in state; always the same instance.
  ValueListenable<AuthState> watchAuthState();

  /// Signs the user in.
  Future<Result<void>> signIn();

  /// Signs the user out.
  Future<Result<void>> signOut();
}
```

---

## Data model mapping

`lib/features/auth/data/models/auth_user_model.dart`

```dart
import '../../domain/entities/auth_user.dart';

/// Storage format of a user.
final class AuthUserModel {
  /// Unique id of the user.
  final String id;

  /// Creates a user model.
  const AuthUserModel({required this.id});

  /// Creates a model from a domain [entity].
  factory AuthUserModel.fromEntity(AuthUser entity) => AuthUserModel(id: entity.id);

  /// Converts the model into a domain entity.
  AuthUser toEntity() => AuthUser(id: id);
}
```

---

## DataSource (Stream allowed)

`lib/features/auth/data/data_sources/auth_data_source.dart`

```dart
import '../models/auth_user_model.dart';

/// Authentication backend (SDK, API).
abstract interface class AuthDataSource {
  /// Emits the current user (or null) and every change.
  Stream<AuthUserModel?> watchUser();

  /// Signs the user in.
  Future<void> signIn();

  /// Signs the user out.
  Future<void> signOut();
}
```

`lib/features/auth/data/data_sources/auth_data_source_impl.dart` — an in-memory stand-in; replace it with your SDK (Firebase, API) behind the same interface:

```dart
import 'dart:async';

import 'package:your_app/core/domain/entities/disposable_resource.dart';

import '../models/auth_user_model.dart';
import 'auth_data_source.dart';

/// In-memory authentication backend.
final class AuthDataSourceImpl implements AuthDataSource, DisposableResource {
  /// Id given to the signed-in user.
  static const String _userId = 'local-user';

  final StreamController<AuthUserModel?> _changes = StreamController<AuthUserModel?>.broadcast();

  AuthUserModel? _user;

  /// Emits the current user right away, then every change; subscribes synchronously.
  @override
  Stream<AuthUserModel?> watchUser() => Stream<AuthUserModel?>.multi(_onListen);

  @override
  Future<void> signIn() async {
    _user = const AuthUserModel(id: _userId);
    _changes.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }

  /// Closes the change stream. Called by DI only.
  @override
  Future<void> dispose() => _changes.close();

  void _onListen(MultiStreamController<AuthUserModel?> listener) {
    listener.add(_user);
    final StreamSubscription<AuthUserModel?> sub = _changes.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = sub.cancel;
  }
}
```

---

## Repository (private ValueNotifier, public ValueListenable)

`lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';
import 'package:your_app/core/domain/entities/result.dart';

import 'package:your_app/core/domain/entities/disposable_resource.dart';

import '../../domain/entities/auth_state.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_data_source.dart';
import '../models/auth_user_model.dart';

/// Auth repository: mirrors the data source into a private [ValueNotifier].
final class AuthRepositoryImpl implements AuthRepository, DisposableResource {
  /// Message shown when sign-in fails.
  static const String _signInFailedMessage = 'Could not sign in';

  /// Message shown when sign-out fails.
  static const String _signOutFailedMessage = 'Could not sign out';

  /// Message shown when the auth state stream fails.
  static const String _watchFailedMessage = 'Could not load the sign-in state';

  static const String _initLog = 'AuthRepository init: subscribed to user changes';
  static const String _disposeLog = 'AuthRepository dispose: unsubscribed';
  static const String _watchFailureLog = 'WatchUser: failure — ';
  static const String _signInSuccessLog = 'SignIn: success — user signed in';
  static const String _signInFailureLog = 'SignIn: failure — ';
  static const String _signOutSuccessLog = 'SignOut: success — user signed out';
  static const String _signOutFailureLog = 'SignOut: failure — ';

  final AuthDataSource _dataSource;

  final Logger _logger;

  final ValueNotifier<AuthState> _state = ValueNotifier(const UnknownAuthState());

  StreamSubscription<AuthUserModel?>? _sub;

  /// Creates the repository.
  AuthRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to user changes; returns this for `registerSingletonAsync`.
  Future<AuthRepositoryImpl> init() async {
    _sub ??= _dataSource.watchUser().listen(_onUser, onError: _onError);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _state.dispose();
    _logger.i(_disposeLog);
  }

  void _onUser(AuthUserModel? model) {
    if (model == null) {
      _state.value = const SignedOutAuthState();
      return;
    }

    final AuthUser entity = model.toEntity();
    _state.value = SignedInAuthState(user: entity);
  }

  void _onError(Object error) {
    _logger.e('$_watchFailureLog$error');
    _state.value = const FailureAuthState(message: _watchFailedMessage);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<AuthState> watchAuthState() => _state;

  @override
  Future<Result<void>> signIn() async {
    try {
      await _dataSource.signIn();
      _logger.i(_signInSuccessLog);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_signInFailureLog$e');
      return const Result.failure(_signInFailedMessage);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      _logger.i(_signOutSuccessLog);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_signOutFailureLog$e');
      return const Result.failure(_signOutFailedMessage);
    }
  }
}
```

---

## Use Case (no try/catch, no async/await)

Use cases MUST NOT have try/catch blocks. The repository layer already handles try/catch and converts errors from data sources into `Result.failure`. The use case simply passes through the repository's `Result` — no `async`/`await` needed:

`lib/features/auth/domain/use_cases/sign_in_use_case.dart`

```dart
import 'package:your_app/core/domain/entities/result.dart';

import '../repositories/auth_repository.dart';

/// Action use case: signs the user in.
final class SignInUseCase {
  final AuthRepository _auth;

  /// Creates the use case.
  SignInUseCase(this._auth);

  /// Signs the user in.
  /// Returns `Result<void>` from the repository — no try/catch, no async/await.
  Future<Result<void>> call() {
    return _auth.signIn();
  }
}
```

`lib/features/auth/domain/use_cases/sign_out_use_case.dart`

```dart
import 'package:your_app/core/domain/entities/result.dart';

import '../repositories/auth_repository.dart';

/// Action use case: signs the user out.
final class SignOutUseCase {
  final AuthRepository _auth;

  /// Creates the use case.
  SignOutUseCase(this._auth);

  /// Signs the user out.
  Future<Result<void>> call() {
    return _auth.signOut();
  }
}
```

---

## Watch Use Case (returns ValueListenable)

`lib/features/auth/domain/use_cases/watch_auth_state_use_case.dart`

```dart
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/auth_state.dart';
import '../repositories/auth_repository.dart';

/// Watch use case: the live sign-in state.
final class WatchAuthStateUseCase {
  final AuthRepository _auth;

  /// Creates the use case.
  WatchAuthStateUseCase(this._auth);

  /// Returns the live auth state; the same instance on every call.
  ValueListenable<AuthState> call() => _auth.watchAuthState();
}
```

---

## DI: `registerAndInitAuth()`

The function in `lib/features/auth/presentation/di/auth_di.dart` (full file with imports: `references/di_patterns.md` → "Feature"). Bottom-up, lazy where possible:

```dart
/// Registers the auth feature and starts its async initialization.
void registerAndInitAuth() {
  // 1. data sources
  di.registerLazySingleton<AuthDataSource>(() => AuthDataSourceImpl(), dispose: disposeResource);

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

---

## Getters

`lib/features/auth/presentation/di/auth_getters.dart`

```dart
import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/watch_auth_state_use_case.dart';

/// Watch use case for the live auth state.
WatchAuthStateUseCase get watchAuthStateUseCase => di<WatchAuthStateUseCase>();

/// Action use case that signs the user in.
SignInUseCase get signInUseCase => di<SignInUseCase>();

/// Action use case that signs the user out.
SignOutUseCase get signOutUseCase => di<SignOutUseCase>();
```

---

## Presentation UI: show state (`watch`)

`lib/features/auth/presentation/widgets/auth_status_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/auth_state.dart';
import '../di/auth_getters.dart';
import 'sign_in_button_widget.dart';

/// Shows the sign-in button or the signed-in label depending on the live auth state;
/// nothing until the state is known.
final class AuthStatusWidget extends WatchingWidget {
  /// Label shown while the user is signed in.
  static const String _signedInText = 'Signed in';

  /// Creates the auth status widget.
  const AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() returns the ValueListenable itself — .value is required here.
    final AuthState state = watch(watchAuthStateUseCase()).value;

    return switch (state) {
      UnknownAuthState() => const SizedBox.shrink(),
      SignedInAuthState() => const Text(_signedInText),
      SignedOutAuthState() || FailureAuthState() => const SignInButtonWidget(),
    };
  }
}
```

---

## Presentation UI: action result (`ResultState` controller + `registerHandler`)

`SignInButtonWidget` and its `SignInController` (`presentation/controllers/sign_in_controller.dart`) — full code in `references/controllers.md` → "With a controller". The controller is a `ValueNotifier<ResultState<void>>` that gets `signInUseCase.call` through its constructor; the button owns it with `createOnce`, watches `controller.value.isLoading` and shows a snackbar from `registerHandler(target: controller, handler: _onActionChanged)`.

---

## Presentation UI: which screen to show (`watch` + `switch`)

Which screen a state needs is **shown**, not navigated to: the gate watches the auth state and picks the widget on every build. The current value counts on the first build too, and a `switch` over the sealed `AuthState` handles every state — protected content is never shown by mistake, and no routes are needed.

`lib/features/auth/presentation/widgets/auth_gate_widget.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/auth_state.dart';
import '../di/auth_getters.dart';

/// Shows [child] only to a signed-in user, [signIn] to everybody else and
/// [loading] until the sign-in state is known.
final class AuthGateWidget extends WatchingWidget {
  /// Content for a signed-in user.
  final Widget child;

  /// Sign-in screen: shown when nobody is signed in or the state could not be loaded.
  final Widget signIn;

  /// Shown until the first sign-in state arrives.
  final Widget loading;

  /// Creates the gate.
  const AuthGateWidget({required this.child, required this.signIn, required this.loading, super.key});

  @override
  Widget build(BuildContext context) {
    final AuthState state = watch(watchAuthStateUseCase()).value;

    return switch (state) {
      UnknownAuthState() => loading,
      SignedInAuthState() => child,
      SignedOutAuthState() || FailureAuthState() => signIn,
    };
  }
}
```

Use it as the root of the app: `MaterialApp(home: AuthGateWidget(loading: …, signIn: …, child: …))`. It rebuilds only when the auth state changes; a new `AuthState` subclass does not compile until the `switch` handles it.
