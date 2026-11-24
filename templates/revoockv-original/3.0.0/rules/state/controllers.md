# Controllers — UI state only, like Flutter's controllers

A controller here means the same thing as in Flutter (`TextEditingController`, `ScrollController`): an object that
holds the **UI state** of a widget. It is never a place for business logic, and it **never calls use cases**.

| Who | Does | Never |
|---|---|---|
| **Controller** | holds UI state: fields, focus, scroll, timers, mode, selection, validation, the progress of an action (`ResultState`) | takes or calls use cases, imports getters, has a `BuildContext` |
| **Owner widget** (a `WatchingWidget` with `createOnce`) | creates the controller, calls `<name>UseCase(...)` in a private method, writes the result into the controller, listens with `watch` / `registerHandler` | — |
| **Leaf widgets** (buttons, tiles, fields, dialogs) | render data and forward events: constructor data, `ValueListenable<T>`, callbacks (`onPressed`, `onChanged`) | know use cases, getters or the controller of a feature — so they can be reused anywhere |

## When a controller is needed

| The widget… | Controller |
|---|---|
| only shows domain state and calls use cases, with nothing to show around the action | **not needed** — the widget watches `watch<Name>UseCase()` and calls the action use case in a private method |
| has its own UI state: progress of an action, the error of the last action, form fields and validation, selection, several `TextEditingController` / `FocusNode` / `ScrollController` that work together | **needed** |

## Naming

- Every controller ends with `Controller`: the class (`SongFormController`), its fields, locals and parameters
  (`savingStateController`, `authorController`, `songFormController`). A `FocusNode` ends with `FocusNode`
  (`passwordFocusNode`). Linter: `controller_naming`.
- The name is a **noun of what it holds**, not an action and not a question: `savingStateController`,
  `signUpModeController`, `scrollingController` — not `saveState`, `save`, `isSignUp`, `isScrollingController`.
- The progress of an action is `<action in -ing>StateController`: `savingStateController`, `signingInStateController`,
  `deletingStateController`.
- A leaf widget that only reads a state takes it as `ValueListenable<T>` named after the state, without the suffix:
  `savingState`, `addingState` — it does not own or control it.

## Shape

A controller is a plain class (or a `ValueNotifier<S>` itself when it holds one value — `TabSelectionController`).
It owns its notifiers and Flutter controllers as public `final` fields and disposes them in `dispose()`:

`lib/features/auth/presentation/controllers/sign_in_controller.dart`

```dart
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:your_app/core/domain/entities/result_state.dart';

import '../../domain/entities/auth_failure.dart';

/// UI state of the sign-in button: the progress of signing in.
///
/// Knows nothing about use cases — the owner calls them and records the outcome here.
final class SignInController {
  /// Progress of signing in; the button is disabled while it runs.
  final ValueNotifier<ResultState<void, AuthFailure>> signingInStateController = ValueNotifier<ResultState<void, AuthFailure>>(
    ResultState.idle,
  );

  bool _isDisposed = false;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Releases the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    signingInStateController.dispose();
  }
}
```

```dart
/// Index of the selected tab.
final class TabSelectionController extends ValueNotifier<int> {
  /// Starts with the first tab selected.
  TabSelectionController() : super(0);

  /// Selects the tab at [index].
  void select(int index) {
    value = index;
  }
}
```

## Rules

- Controllers live in `presentation/controllers/` (`<name>_controller.dart`, class `<Name>Controller`). Loading /
  success / failure state is always the shared `ResultState<T, F>` (`core/domain/entities/result_state.dart`).
- **A controller is self-contained, like `TextEditingController`:** it imports only Flutter, `core/` and domain
  entities — never `<feature>_getters.dart`, use cases, repositories, data sources, services or models, and never
  calls `di` / GetIt (linter: `import_violation`).
- **A controller takes no actions:** no constructor parameters, fields or typedefs of functions returning
  `Future<Result>` (linter: `controller_no_actions`). The owner widget calls the use case — `signInUseCase()`,
  never `signInUseCase.call`.
- **One state — one notifier:** the state of one thing is one value (a sealed class, an enum, `ResultState`), not
  `isLoading` + `error`. Two actions that run independently (adding and deleting) get two notifiers.
- **`isDisposed`:** a controller that the owner writes to after an `await` keeps `bool _isDisposed` and exposes
  `bool get isDisposed`; the owner checks it after every `await` — the user may leave the screen while the request
  runs, and writing to a disposed notifier throws.
- Domain/data state is never copied into a controller: wrappers select it from `watch<Name>UseCase()`.
- Controllers are never registered in GetIt (linter: `no_state_in_di`). `setState`, custom mixins and bindings
  (GetX-style) are not used (Flutter's `TickerProviderStateMixin` for `vsync` is fine).

## Owner and rebuilds

- **The owner is the page, a `WatchingWidget` with `createOnce`:**
  `final NotesController notesController = createOnce(_createNotesController, dispose: _disposeNotesController);` —
  created on the first build, the same object on every rebuild, disposed with the widget. The create / dispose methods
  are private static methods (no inline closures). `createOnce` follows the order rule like `watch()` (linter:
  `watch_order`, `controller_lifecycle`).
- **The owner calls the use case** in a private method that gets the controller as its argument
  (`onPressed: () => _onSavePressed(songFormController)` — a closure that only forwards values is allowed):

  1. return when the action is already running (`if (savingStateController.value.isLoading) return;`) — a double tap
     does not run it twice;
  2. set `ResultState.loading`, `await` the use case;
  3. `if (controller.isDisposed) return;`
  4. set `ResultState.of(result)` — every failure is a new instance, so the same error twice shows twice.

- **No `State` for owning resources.** A Flutter controller that the UI state needs belongs to the controller; a lone
  one that only the widget needs (a `ScrollController` of one list) is created with `createOnce`. A `StatefulWidget`
  stays only where the framework needs a `State` (`AnimationController`, `didUpdateWidget`) or in a dumb widget that
  owns a plain Flutter controller (`wrappers.md`).
- **As few rebuilds as possible, as low as possible:** the owner usually only reacts —
  `registerHandler(target: controller.savingStateController, handler: _onSavingChanged)` runs the handler and **does
  not rebuild**. The owner passes the notifier down as `ValueListenable<S>` to a wrapper, which selects the part its
  dumb widget shows (`wrappers.md`).

| Event | What rebuilds |
|---|---|
| an action starts / ends | only the wrapper that selects `isLoading` and its dumb button |
| an action fails | nothing — the owner's `registerHandler` shows a snackbar |
| domain data changes | only the wrappers whose selection from `watch<Name>UseCase()` changed |

## Without a controller: the page calls the use case

`lib/features/auth/presentation/pages/account_page.dart`

```dart
import 'package:flutter/material.dart';

import '../di/auth_getters.dart';
import '../widgets/account_header_widget.dart';

/// The account screen: signs the user out; nothing is shown while signing out.
final class AccountPage extends StatelessWidget {
  /// Label of the sign-out button.
  static const String _signOutLabel = 'Sign out';

  /// Creates the page.
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountHeaderWidget(signOutLabel: _signOutLabel, onSignOutPressed: _onSignOutPressed);
  }

  static void _onSignOutPressed() {
    signOutUseCase();
  }
}
```

`lib/features/auth/presentation/widgets/account_header_widget.dart`

```dart
import 'package:flutter/material.dart';

/// Header of the account screen with a sign-out button. Dumb: the label and the callback come from the page.
final class AccountHeaderWidget extends StatelessWidget {
  /// Label of the sign-out button.
  final String signOutLabel;

  /// Called when the sign-out button is pressed.
  final VoidCallback onSignOutPressed;

  /// Creates the header.
  const AccountHeaderWidget({required this.signOutLabel, required this.onSignOutPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(onPressed: onSignOutPressed, child: Text(signOutLabel)),
    );
  }
}
```

The auth gate reacts to the new `SignedOutAuthState` — the action shows no progress, so it needs no controller.

## With a controller: the page calls the use case, the controller holds the state

The page creates the controller, calls the use case and records the outcome in the controller; it **reacts** to a
failure with `registerHandler()`; a wrapper **shows** the progress to a dumb button (`wrappers.md`).

`lib/features/auth/presentation/pages/sign_in_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:your_app/core/domain/entities/result.dart';
import 'package:your_app/core/domain/entities/result_state.dart';

import '../../domain/entities/auth_failure.dart';
import '../controllers/sign_in_controller.dart';
import '../di/auth_getters.dart';
import '../l10n/auth_failure_text.dart';
import '../wrappers/sign_in_button_wrapper.dart';

/// The sign-in screen: owns the [SignInController], signs the user in and shows a snackbar when it fails.
///
/// Never rebuilds: the wrapper of the button selects the progress.
final class SignInPage extends WatchingWidget {
  /// Label of the button.
  static const String _signInLabel = 'Sign in';

  /// Creates the page.
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignInController signInController = createOnce(_createSignInController, dispose: _disposeSignInController);
    registerHandler(target: signInController.signingInStateController, handler: _onSigningInChanged);

    return Center(
      child: SignInButtonWrapper(
        signingInState: signInController.signingInStateController,
        signInLabel: _signInLabel,
        onSignInPressed: () => _onSignInPressed(signInController),
      ),
    );
  }

  static SignInController _createSignInController() => SignInController();

  static void _disposeSignInController(SignInController signInController) => signInController.dispose();

  void _onSigningInChanged(BuildContext context, ResultState<void, AuthFailure> state, void Function() cancel) {
    if (state is! FailureResultState<void, AuthFailure>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text)));
  }

  /// Signs the user in; ignored while an attempt runs.
  Future<void> _onSignInPressed(SignInController signInController) async {
    final ValueNotifier<ResultState<void, AuthFailure>> signingInStateController = signInController.signingInStateController;
    if (signingInStateController.value.isLoading) return;
    signingInStateController.value = ResultState.loading;

    final Result<void, AuthFailure> result = await signInUseCase();
    if (signInController.isDisposed) return;

    signingInStateController.value = ResultState.of(result);
  }
}
```

`lib/features/auth/presentation/wrappers/sign_in_button_wrapper.dart`

```dart
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:your_app/core/domain/entities/result_state.dart';

import '../../domain/entities/auth_failure.dart';
import '../widgets/sign_in_button_widget.dart';

/// Gives [SignInButtonWidget] whether signing in runs: rebuilds only when it starts or ends.
final class SignInButtonWrapper extends WatchingWidget {
  /// Progress of signing in, kept by the page's controller.
  final ValueListenable<ResultState<void, AuthFailure>> signingInState;

  /// Label of the button.
  final String signInLabel;

  /// Called when the button is pressed; the page signs in.
  final VoidCallback onSignInPressed;

  /// Creates the wrapper.
  const SignInButtonWrapper({
    required this.signingInState,
    required this.signInLabel,
    required this.onSignInPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSigningIn = watchPropertyValue(_isSigningInOf, target: signingInState);
    return SignInButtonWidget(isSigningIn: isSigningIn, signInLabel: signInLabel, onSignInPressed: onSignInPressed);
  }

  static bool _isSigningInOf(ValueListenable<ResultState<void, AuthFailure>> state) => state.value.isLoading;
}
```

`lib/features/auth/presentation/widgets/sign_in_button_widget.dart`

```dart
import 'package:flutter/material.dart';

/// The sign-in button, off while signing in. Dumb: the flag, the label and the callback come from above.
final class SignInButtonWidget extends StatelessWidget {
  /// Whether signing in runs; the button is off meanwhile.
  final bool isSigningIn;

  /// Label of the button.
  final String signInLabel;

  /// Called when the button is pressed.
  final VoidCallback onSignInPressed;

  /// Creates the button.
  const SignInButtonWidget({
    required this.isSigningIn,
    required this.signInLabel,
    required this.onSignInPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: isSigningIn ? null : onSignInPressed, child: Text(signInLabel));
  }
}
```

Rules of the pattern:
- **The use case is called by the owner** with its real arguments: `addSongUseCase(author: …, name: …)`,
  `signInUseCase()` — never a `.call` tear-off, never passed into a controller.
- **The sync handlers go above the async methods** in the class: `async_gap_context_mounted` reads the class top to
  bottom.
- **`BuildContext` after `await`** in a handler: check `if (!context.mounted) return;` before using it (linter:
  `async_gap_context_mounted`).
