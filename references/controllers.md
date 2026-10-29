# Controllers — UI logic only

A controller holds the **UI logic** of a widget: state that exists only on the screen. It is never a place for business logic or data access.

## When a controller is needed

| The widget… | Controller |
|---|---|
| only shows domain state and forwards user actions to use cases, with nothing to show around the action | **not needed** — the widget watches `watch<Name>UseCase()` and calls the action use case in a private method |
| has its own UI logic: progress of an action, the error of the last action, form state and validation hints, selection, several `TextEditingController` / `FocusNode` / `ScrollController` that work together | **needed** |

## One state — one notifier

The state of one thing is **one** value: a sealed class (or an enum), not several notifiers. `isLoading` + `error` are states of one action, so they are one value — the shared `ResultState<void>` from core (`references/result_state.md`). Split state into several notifiers only when its parts change independently and different widgets read them.

## Shape

1. **A `ValueNotifier<S>` itself** (preferred): `S` is `ResultState<T>`, a sealed class or an enum — `SignInController` below, `TabSelectionController`:

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

2. **Owning Flutter controllers** that belong to the UI logic (`TextEditingController`, `FocusNode`, `ScrollController`): the controller creates them as public `final` fields, reads them itself and disposes them in its `dispose()`. `NotesController` (`assets/example_app/`) is a `ValueNotifier<ResultState<void>>` that owns `final TextEditingController text`: `addNote()` reads `text.text` and clears it **only after success**, so a failed note keeps its text. The field widget only receives `controller.text`.

## Rules

- Controllers live in `presentation/controllers/` (`<name>_controller.dart`, class `<Name>Controller`; a state class of its own — `<name>_state.dart`). Loading / success / failure state is always the shared `ResultState<T>` (`core/domain/entities/result_state.dart`).
- **A controller is self-contained, like `TextEditingController`:** it can be moved to any app as is. It imports only Flutter, `core/` and domain entities — never `<feature>_getters.dart`, use cases, repositories, data sources, services, models, and never calls `di` / GetIt (linter: `import_violation`).
- **Use cases come in as functions through the constructor:** `SignInController(signIn: signInUseCase.call)`. The controller calls them itself — it decides when (and whether) an action starts: not while another one runs.
- Domain/data state is never copied into a controller: widgets watch it with `watch(watch<Name>UseCase()).value`.
- A controller has no `BuildContext`: navigation, snackbars and dialogs stay in the widget's `registerHandler` handlers.
- Controllers are never registered in GetIt (linter: `no_state_in_di`). `setState`, custom mixins and bindings (GetX-style) are not used (Flutter's `TickerProviderStateMixin` for `vsync` is fine).

## Owner and rebuilds

- **The owner is a `WatchingWidget` with `createOnce`:** `final NotesController controller = createOnce(_createController, dispose: _disposeController);` — created on the first build, the same object on every rebuild, disposed with the widget. `_createController` / `_disposeController` are private static methods (no inline closures). `createOnce` follows the order rule like `watch()` (linter: `watch_order`, `controller_lifecycle`).
- **No `State` for owning resources.** A Flutter controller that the UI logic reads (the text of a form) belongs to the controller; a lone one that only the widget needs (a `ScrollController` of one list) is created with `createOnce(_createScroll, dispose: _disposeScroll)`. A `StatefulWidget` stays only where the framework needs a `State`: `AnimationController` (its `vsync` comes from `SingleTickerProviderStateMixin`), `didUpdateWidget`.
- **As few rebuilds as possible, as low as possible:** the owner usually only reacts — `registerHandler(target: controller, handler: _onActionChanged)` runs the handler and **does not rebuild**. `watch(controller).value` goes into the lowest widget that shows the value; the owner passes the controller down as `ValueListenable<S>`.

| Event | What rebuilds |
|---|---|
| an action starts / ends | only the widget that watches `isLoading` (the button) |
| an action fails | nothing — the owner's `registerHandler` shows a snackbar |
| domain data changes | only the widget that watches `watch<Name>UseCase()` |

## Without a controller: the widget calls the use case

`lib/features/auth/presentation/widgets/account_header_widget.dart`

```dart
import 'package:flutter/material.dart';

import '../di/auth_getters.dart';

/// Header of the account screen with a sign-out button; nothing is shown while signing out.
final class AccountHeaderWidget extends StatelessWidget {
  /// Label of the sign-out button.
  static const String _signOutText = 'Sign out';

  /// Creates the header.
  const AccountHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(onPressed: _onSignOutPressed, child: const Text(_signOutText)),
    );
  }

  void _onSignOutPressed() {
    signOutUseCase();
  }
}
```

The auth gate reacts to the new `SignedOutAuthState` — the button itself has no UI state, so it needs no controller.

## With a controller: action → `ResultState` → `watch` / `registerHandler`

The owner creates the controller with the use case; the controller runs it and records the outcome as an `ResultState<void>`; the widget **shows** progress with `watch()` and **reacts** to a failure with `registerHandler()`.

`lib/features/auth/presentation/controllers/sign_in_controller.dart`

```dart
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:your_app/core/domain/entities/result_state.dart';
import 'package:your_app/core/domain/entities/result.dart';

/// UI state of the sign-in button: one [ResultState].
///
/// Knows nothing about DI or use cases — the owner passes the action in.
final class SignInController extends ValueNotifier<ResultState<void>> {
  final Future<Result<void>> Function() _signIn;

  bool _isDisposed = false;

  /// Creates the controller with the sign-in action it runs.
  SignInController({required this._signIn}) : super(ResultState.idle);

  /// Signs the user in; ignored while an attempt runs.
  Future<void> signIn() async {
    if (value.isLoading) return;
    value = ResultState.loading;

    final Result<void> result = await _signIn();
    if (_isDisposed) return;

    value = ResultState.of(result);
  }

  /// Releases the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
```

`lib/features/auth/presentation/widgets/sign_in_button_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:your_app/core/domain/entities/result_state.dart';

import '../controllers/sign_in_controller.dart';
import '../di/auth_getters.dart';

/// Sign-in button that shows a snackbar when sign-in fails.
final class SignInButtonWidget extends WatchingWidget {
  /// Label of the button.
  static const String _signInText = 'Sign in';

  /// Creates the button.
  const SignInButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final SignInController controller = createOnce(_createController, dispose: _disposeController);
    final bool isLoading = watch(controller).value.isLoading;
    registerHandler(target: controller, handler: _onActionChanged);

    return ElevatedButton(
      onPressed: isLoading ? null : controller.signIn,
      child: const Text(_signInText),
    );
  }

  static SignInController _createController() => SignInController(signIn: signInUseCase.call);

  static void _disposeController(SignInController controller) => controller.dispose();

  void _onActionChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    if (state is! FailureResultState<void>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
  }
}
```

Here the button is the lowest widget that shows the state, so it both owns and watches the controller. On a page the owner only reacts, and a small child watches — `assets/example_app/lib/features/notes/presentation/pages/notes_page.dart`.

Rules of the pattern:
- **The use case is a constructor argument** (`signInUseCase.call` — an explicit tear-off of the callable use case). The same controller works with any action, and its test passes a plain function instead of DI.
- **Ignore a second start while running** (`if (value.isLoading) return;`): a double tap does not run the action twice.
- **Every failure is a new instance** (`ResultState.of(result)`): a `ValueNotifier` notifies only when the value changes, so a new instance shows the same error twice — no reset needed.
- **`_isDisposed` after every `await`** — the controller's equivalent of `context.mounted`: the user may leave the screen while the request runs, and writing to a disposed notifier throws.
- **`BuildContext` after `await`** in a `State` method: check `if (!mounted) return;` before using `context` (linter: `async_gap_context_mounted`). Prefer the pattern above — handlers receive a fresh `context`.
