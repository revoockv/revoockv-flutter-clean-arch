# Auth feature — domain

A worked feature on every layer (sign in / out). It is the golden path: when uncertain, copy it and rename only.
Its code is compiled inside `example/` by `scripts/selfcheck.py`. Parts: `auth_domain.md` (entities, repository,
use cases), `auth_data.md` (model, data source, repository), `auth_presentation.md` (DI, getters, widgets).

It enforces:

- Controllers only when there is UI state (a plain class with notifiers, or a `ValueNotifier` itself), like Flutter's controllers; they never call use cases and never touch the data layer.
- DataSource may use Streams; repository owns a private ValueNotifier and exposes ValueListenable.
- Models (DTO) convert to/from Domain entities in the model class.
- UI reads state only as `watch(watch<Name>UseCase()).value` via top-level getters.
- Which screen to show is a `watch` + `switch` over the state (`AuthGateWidget`); one-off reactions (snackbars) go through `registerHandler(target: …, handler: _onX)`.
- Use cases are always called by a widget (`signInUseCase()`). When the UI shows the progress or error of the action, the widget records it in a `<action>StateController` of its UI controller and shows a failure with `registerHandler`; an action with nothing to show needs no controller.
- Result is used for success/failure.
- Use cases pass through repository Result — no try/catch in use cases.

## Core

Create (copy from `example/lib/core/`, or run `scripts/init_feature.py --core`):
- `lib/core/domain/entities/result.dart` — `rules/errors_models/result.md`
- `lib/core/domain/entities/disposable_resource.dart` and `lib/core/presentation/di/core_di.dart` — `rules/di/di_patterns.md`
- `lib/core/presentation/theme.dart` — values shared by several features (`rules/style/constants.md`)

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
