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

## Presentation UI: action result (UI controller + `registerHandler`)

`SignInButtonWidget` and its `SignInController` (`presentation/controllers/sign_in_controller.dart`) — full code in `rules/state/controllers.md` → "With a controller". The controller only holds `signingInStateController` (a `ValueNotifier<ResultState<void>>`); the button owns it with `createOnce`, calls `signInUseCase()` itself, watches `signingInStateController.value.isLoading` and shows a snackbar from `registerHandler(target: signInController.signingInStateController, handler: _onSigningInChanged)`.

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
