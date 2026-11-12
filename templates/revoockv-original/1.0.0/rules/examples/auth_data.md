# Auth feature — data

Part of the auth feature (`auth_domain.md`).

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
