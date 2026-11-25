# Auth feature — presentation

Part of the auth feature (`auth_domain.md`).

## DI: `registerAndInitAuth()`

The function in `lib/features/auth/presentation/di/auth_di.dart` (full file with imports: `rules/di/di_patterns.md` → "Feature"). Bottom-up, lazy where possible:

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

## Presentation UI: show state (a wrapper and a dumb widget)

`lib/features/auth/presentation/wrappers/auth_status_wrapper.dart`

```dart
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/auth_state.dart';
import '../di/auth_getters.dart';
import '../widgets/auth_status_widget.dart';

/// Gives [AuthStatusWidget] whether the user is signed in (`null` until it is known): rebuilds only when that flips.
final class AuthStatusWrapper extends WatchingWidget {
  /// Label shown while the user is signed in.
  final String signedInText;

  /// Shown to a user who is not signed in.
  final Widget signIn;

  /// Creates the wrapper.
  const AuthStatusWrapper({required this.signedInText, required this.signIn, super.key});

  @override
  Widget build(BuildContext context) {
    final bool? isSignedIn = watchPropertyValue(_isSignedInOf, target: watchAuthStateUseCase());
    return AuthStatusWidget(isSignedIn: isSignedIn, signedInText: signedInText, signIn: signIn);
  }

  static bool? _isSignedInOf(ValueListenable<AuthState> state) => switch (state.value) {
    UnknownAuthState() => null,
    SignedInAuthState() => true,
    SignedOutAuthState() || FailureAuthState() => false,
  };
}
```

`lib/features/auth/presentation/widgets/auth_status_widget.dart`

```dart
import 'package:flutter/material.dart';

/// The signed-in label or the sign-in part; nothing until the state is known. Dumb: everything comes from above.
final class AuthStatusWidget extends StatelessWidget {
  /// Whether the user is signed in; `null` until it is known.
  final bool? isSignedIn;

  /// Label shown while the user is signed in.
  final String signedInText;

  /// Shown to a user who is not signed in.
  final Widget signIn;

  /// Creates the widget.
  const AuthStatusWidget({required this.isSignedIn, required this.signedInText, required this.signIn, super.key});

  @override
  Widget build(BuildContext context) => switch (isSignedIn) {
    null => const SizedBox.shrink(),
    true => Text(signedInText),
    false => signIn,
  };
}
```

---

## Presentation UI: action result (page + controller + wrapper)

`SignInPage`, its `SignInController` (`presentation/controllers/sign_in_controller.dart`), `SignInButtonWrapper` and
the dumb `SignInButtonWidget` — full code in `rules/state/controllers.md` → "With a controller". The page owns the
controller with `createOnce`, calls `signInUseCase()` and shows a snackbar from
`registerHandler(target: signInController.signingInStateController, handler: _onSigningInChanged)`; the wrapper
selects `isLoading` with `watchPropertyValue` and gives the button a `bool`.

---

## Presentation UI: which screen to show (a wrapper with slots)

Which screen a state needs is **shown**, not navigated to: the gate selects which of three screens the auth state
needs and returns it. The current value counts on the first build too, and a `switch` over the sealed `AuthState`
handles every state — protected content is never shown by mistake, and no routes are needed.

`lib/features/auth/presentation/wrappers/auth_gate_wrapper.dart`

```dart
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/auth_state.dart';
import '../di/auth_getters.dart';

/// Shows [child] only to a signed-in user, [signIn] to everybody else and [loading] until the sign-in state is known.
///
/// Selects only which screen is needed, so a new `AuthState` of the same kind rebuilds nothing.
final class AuthGateWrapper extends WatchingWidget {
  /// Content for a signed-in user.
  final Widget child;

  /// Sign-in screen: shown when nobody is signed in or the state could not be loaded.
  final Widget signIn;

  /// Shown until the first sign-in state arrives.
  final Widget loading;

  /// Creates the gate.
  const AuthGateWrapper({required this.child, required this.signIn, required this.loading, super.key});

  @override
  Widget build(BuildContext context) {
    final _Screen screen = watchPropertyValue(_screenOf, target: watchAuthStateUseCase());
    return switch (screen) {
      _Screen.loading => loading,
      _Screen.child => child,
      _Screen.signIn => signIn,
    };
  }

  static _Screen _screenOf(ValueListenable<AuthState> state) => switch (state.value) {
    UnknownAuthState() => _Screen.loading,
    SignedInAuthState() => _Screen.child,
    SignedOutAuthState() || FailureAuthState() => _Screen.signIn,
  };
}

/// Which screen the gate shows.
enum _Screen { loading, child, signIn }
```

Use it as the root of the app: `MaterialApp(home: AuthGateWrapper(loading: …, signIn: const SignInPage(), child: …))`.
A new `AuthState` subclass does not compile until the `switch` handles it.

---

## Presentation: failure text

The domain says what went wrong (`AuthFailure`); the words live in `presentation/l10n` — an exhaustive `switch`, so a
new failure without a text does not compile. An app with translations reads the strings of the current language here
(`String text(Translations t)`); the rule is in `rules/errors_models/result.md`.

`lib/features/auth/presentation/l10n/auth_failure_text.dart`

```dart
import '../../domain/entities/auth_failure.dart';

/// The text of an [AuthFailure] shown to the user.
extension AuthFailureText on AuthFailure {
  static const String _signIn = 'Could not sign in';
  static const String _signOut = 'Could not sign out';
  static const String _load = 'Could not load the sign-in state';

  /// The human-readable text of this failure.
  String get text => switch (this) {
        AuthFailure.signIn => _signIn,
        AuthFailure.signOut => _signOut,
        AuthFailure.load => _load,
      };
}
```
