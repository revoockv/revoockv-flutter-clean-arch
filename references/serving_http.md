# Serving the app's use cases over HTTP (Relic)

A Flutter app can serve its own use cases to other devices on the same network — a phone app that searches
the desktop app's data, a script, another computer. The server is **one feature** (`api_server`): its
presentation layer has **routes** — another kind of UI next to pages and widgets — that call the use cases
other features already have. No feature changes for it, and no logic is duplicated.

Platforms: macOS, Windows, Linux, Android, iOS (`dart:io`); not web. On macOS with the App Sandbox enabled add
`com.apple.security.network.server` to both entitlements files; the first start asks the firewall.

## Package

```yaml
dependencies:
  relic: ^1.2.0
```

Relic exports its own `Result` and `Logger` — import it **only with `show`**, and name the extensions you use
(`RouteEx` for `router.get/post`, `HeadersEx` for `request.headers.authorization`, `RelicAppIOServeEx` for `serve`,
`PathParametersRequestEx` + `RawEx` for path parameters).

## Layout of the feature

```
lib/features/api_server/
  domain/entities/api_server_state.dart          — Stopped / Running(port, token) / Failed(message)
  domain/repositories/api_server_repository.dart
  domain/use_cases/                              — watch state, start, stop, check token
  data/data_sources/api_server_data_source.dart  — start(port) → real port, stop()
  data/data_sources/relic_api_server_data_source.dart — RelicApp + the routes + the middleware
  data/repositories/api_server_repository_impl.dart   — ValueNotifier<ApiServerState>, the token
  presentation/routes/<feature>_routes.dart      — one class per served feature, over its use cases
  presentation/dto/                              — API formats (separate from data models)
  presentation/middleware/api_token_middleware.dart
  presentation/di/api_server_di.dart             — builds the routes from other features' getters
  presentation/pages/, widgets/                  — the on/off switch, port, token
lib/core/presentation/routes/json_responses.dart, json_requests.dart
lib/core/presentation/dto/error_dto.dart
```

`routes/`, `dto/` and `middleware/` are optional presentation folders: only a serving feature has them (and
`core/presentation/` for the shared JSON helpers). Files end with `_routes.dart`, `_dto.dart`, `_middleware.dart`.

They are not Flutter layers, so the project lists them in its `.clean_arch_ignore` (SKILL.md → "Automated linting")
and the linter skips them:

```
lib/core/presentation/dto
lib/core/presentation/routes
lib/features/*/presentation/dto
lib/features/*/presentation/middleware
lib/features/*/presentation/routes
```

## Rules

1. **Routes translate, use cases decide.** A handler reads the request (shape only: is it JSON, is `text` a
   string), calls one use case, answers with `result.when(success: _xResponse, failure: JsonResponses.failure)`.
2. **Routes get use cases as functions** through the constructor, like controllers — `watchNotes: watchNotesUseCase.call`.
   They never import getters, use cases, repositories or DI, so a test builds them
   with plain functions.
3. **Only `api_server_di.dart` knows the other features**: it builds the routes with their getters and hands
   them to the data source as Relic `RouterInjectable`s. Register `registerAndInitApiServer()` after the features it serves.
4. **The server is off by default**; the user turns it on (`startApiServerUseCase()`), and `dispose()` stops it
   (`di.reset()`, app exit).
5. **Every request carries a token** (`Authorization: Bearer <token>`); the middleware rejects others with `401`
   before any route runs. The token comes from `Random.secure()` (256 bits) and is compared in constant time.
   In the example it lives from start to stop; an app that pairs devices gives each device its own token.
6. **Failures:** a Flutter `Result` carries only a message, so every use case failure is `400 {"error": message}`;
   live data still loading (`ResultState.loading`) is `503`. Exceptions inside a handler are bugs → Relic answers `500`.
7. **Never accept a file path from a client** — use case parameters that are paths on this device stay closed.
8. **Long work** (minutes) does not hold a request open: answer `202` with a job id and report the progress
   over a WebSocket (`WebSocketUpgrade`) or let the client ask for the job.
9. **Listen on every interface** (`InternetAddress.anyIPv4`) only when serving other devices; tests use
   `InternetAddress.loopbackIPv4` and port `0`.

## Code

`lib/features/api_server/domain/entities/api_server_state.dart`

```dart
/// Whether the app serves its use cases over the local network.
sealed class ApiServerState {
  const ApiServerState();
}

/// The server is off — the default.
final class StoppedApiServerState extends ApiServerState {
  /// Creates the state.
  const StoppedApiServerState();
}

/// The server listens on [port]; clients send `Authorization: Bearer <token>`.
final class RunningApiServerState extends ApiServerState {
  /// Port the server listens on.
  final int port;

  /// Token every request must carry; a new one on every start.
  final String token;

  /// Creates the state.
  const RunningApiServerState({required this.port, required this.token});
}

/// The server could not start, e.g. the port is taken.
final class FailedApiServerState extends ApiServerState {
  /// Human-readable reason.
  final String message;

  /// Creates the state.
  const FailedApiServerState(this.message);
}
```

`lib/features/api_server/domain/repositories/api_server_repository.dart`

```dart
import 'package:your_app/core/domain/entities/result.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/api_server_state.dart';

/// The local network server of the app.
abstract interface class ApiServerRepository {
  /// Live state of the server; always the same instance.
  ValueListenable<ApiServerState> watchState();

  /// Starts the server with a new token; does nothing when it already runs.
  Future<Result<void>> start();

  /// Stops the server; does nothing when it is off.
  Future<Result<void>> stop();

  /// Whether [token] is the token of the running server.
  bool isTokenValid(String token);
}
```

`lib/features/api_server/domain/use_cases/check_api_token_use_case.dart`

```dart
import '../repositories/api_server_repository.dart';

/// Query use case: is a request allowed to call the app's use cases?
final class CheckApiTokenUseCase {
  final ApiServerRepository _repository;

  /// Creates the use case.
  CheckApiTokenUseCase(this._repository);

  /// Whether [token] is the token of the running server; always `false` when it is off.
  bool call(String token) => _repository.isTokenValid(token);
}
```

`lib/features/api_server/data/data_sources/api_server_data_source.dart`

```dart
/// An HTTP server on the local network.
abstract interface class ApiServerDataSource {
  /// Starts listening on [port] (`0` = any free port) on every network interface; returns the real port.
  Future<int> start({required int port});

  /// Stops listening; waits for the requests in flight.
  Future<void> stop();
}
```

`lib/features/api_server/data/data_sources/relic_api_server_data_source.dart`

```dart
import 'dart:io';

import 'package:your_app/core/domain/entities/disposable_resource.dart';
import 'package:relic/relic.dart' show Middleware, RelicApp, RelicAppIOServeEx, RelicServer, RouterInjectable;

import 'api_server_data_source.dart';

/// Serves [_routes] behind [_middleware] with Relic; a new `RelicApp` on every start.
final class RelicApiServerDataSource implements ApiServerDataSource, DisposableResource {
  static const String _rootPath = '/';

  final List<RouterInjectable> _routes;

  final List<Middleware> _middleware;

  final InternetAddress _address;

  RelicApp? _app;

  /// Creates the data source; [_address] defaults to every IPv4 interface, so phones on the same Wi-Fi reach it.
  RelicApiServerDataSource({required this._routes, required this._middleware, InternetAddress? address})
    : _address = address ?? InternetAddress.anyIPv4;

  @override
  Future<int> start({required int port}) async {
    final RelicApp app = RelicApp();
    for (final Middleware middleware in _middleware) {
      app.use(_rootPath, middleware);
    }
    _routes.forEach(app.inject);
    final RelicServer server = await app.serve(address: _address, port: port);
    _app = app;
    return server.port;
  }

  @override
  Future<void> stop() async {
    await _app?.close();
    _app = null;
  }

  /// Stops the server. Called by DI only.
  @override
  Future<void> dispose() => stop();
}
```

`lib/features/api_server/data/repositories/api_server_repository_impl.dart`

```dart
import 'dart:convert';
import 'dart:math';

import 'package:your_app/core/domain/entities/disposable_resource.dart';
import 'package:your_app/core/domain/entities/result.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/api_server_state.dart';
import '../../domain/repositories/api_server_repository.dart';
import '../data_sources/api_server_data_source.dart';

/// Starts and stops the server, owns its state and the token of the running server.
final class ApiServerRepositoryImpl implements ApiServerRepository, DisposableResource {
  /// Port of the server unless DI or a test gives another.
  static const int _defaultPort = 8080;

  /// Random bytes in a token (256 bits).
  static const int _tokenBytes = 32;

  /// Largest value of one random byte, exclusive.
  static const int _byteRange = 256;

  /// Padding that base64Url adds and a token does not need.
  static const String _base64Padding = '=';

  static const String _startFailedMessage = 'Could not start the server — is the port taken?';
  static const String _stopFailedMessage = 'Could not stop the server';

  static const String _startSuccessLog = 'StartApiServer: success — listening on port ';
  static const String _startSkippedLog = 'StartApiServer: skipped — already running';
  static const String _startFailureLog = 'StartApiServer: failure — ';
  static const String _stopSuccessLog = 'StopApiServer: success — stopped';
  static const String _stopFailureLog = 'StopApiServer: failure — ';
  static const String _disposeLog = 'ApiServerRepository dispose: server stopped';

  final ApiServerDataSource _dataSource;

  final Logger _logger;

  final int _port;

  final Random _random = Random.secure();

  final ValueNotifier<ApiServerState> _state = ValueNotifier<ApiServerState>(const StoppedApiServerState());

  /// Creates the repository; once started the server listens on [_port] (8080 by default, `0` = any free port).
  ApiServerRepositoryImpl({required this._dataSource, required this._logger, this._port = _defaultPort});

  /// Stops the server and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await stop();
    _state.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ApiServerState> watchState() => _state;

  @override
  Future<Result<void>> start() async {
    if (_state.value is RunningApiServerState) {
      _logger.w(_startSkippedLog);
      return Result.ok;
    }
    try {
      final int port = await _dataSource.start(port: _port);
      _state.value = RunningApiServerState(port: port, token: _newToken());
      _logger.i('$_startSuccessLog$port');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_startFailureLog$e');
      _state.value = const FailedApiServerState(_startFailedMessage);
      return const Result.failure(_startFailedMessage);
    }
  }

  @override
  Future<Result<void>> stop() async {
    if (_state.value is! RunningApiServerState) return Result.ok;
    try {
      await _dataSource.stop();
      _state.value = const StoppedApiServerState();
      _logger.i(_stopSuccessLog);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_stopFailureLog$e');
      return const Result.failure(_stopFailedMessage);
    }
  }

  @override
  bool isTokenValid(String token) {
    final ApiServerState state = _state.value;
    return state is RunningApiServerState && _sameText(state.token, token);
  }

  String _newToken() => base64Url.encode(List<int>.generate(_tokenBytes, _randomByte)).replaceAll(_base64Padding, '');

  int _randomByte(int _) => _random.nextInt(_byteRange);

  /// Compares in constant time, so the time of an answer tells nothing about the token.
  bool _sameText(String a, String b) {
    if (a.length != b.length) return false;
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
```

`lib/core/presentation/routes/json_responses.dart`

```dart
import 'dart:convert';

import 'package:relic/relic.dart' show Body, MimeType, Response;

import '../dto/error_dto.dart';

/// Builds the JSON responses of the app's HTTP server.
///
/// A failed `Result` carries only a message, so every failure of a use case is `400` with `{"error": message}`.
final class JsonResponses {
  const JsonResponses._();

  /// `200 OK` with [json] as the body.
  static Response ok(Object? json) => Response.ok(body: _body(json));

  /// `204 No Content` — a command succeeded and returns nothing.
  static Response noContent() => Response.noContent();

  /// `400 Bad Request` with `{"error": error}` — the `failure:` callback of `Result.when`.
  static Response failure(String error) => Response.badRequest(body: _error(error));

  /// `401 Unauthorized` with `{"error": error}` — no token or a wrong one.
  static Response unauthorized(String error) => Response.unauthorized(body: _error(error));

  /// `503 Service Unavailable` with `{"error": error}` — the data is not loaded yet.
  static Response unavailable(String error) => Response(HttpStatusCodes.serviceUnavailable, body: _error(error));

  static Body _error(String error) => _body(ErrorDto(error).toJson());

  static Body _body(Object? json) => Body.fromString(jsonEncode(json), mimeType: MimeType.json);
}

/// HTTP status codes Relic has no named constructor for.
final class HttpStatusCodes {
  /// `503 Service Unavailable`.
  static const int serviceUnavailable = 503;

  const HttpStatusCodes._();
}
```

`lib/core/presentation/routes/json_requests.dart`

```dart
import 'dart:convert';

import 'package:relic/relic.dart' show MaxBodySizeExceeded, Request;

import '../../domain/entities/result.dart';

/// Reads JSON request bodies; malformed input becomes a failed [Result].
final class JsonRequests {
  /// Largest accepted body, in bytes (1 MiB).
  static const int _maxBodyBytes = 1024 * 1024;

  static const String _invalidJsonMessage = 'The body is not valid JSON';
  static const String _notObjectMessage = 'The body must be a JSON object';
  static const String _tooLargeMessage = 'The body is too large';

  const JsonRequests._();

  /// Reads the body of [request] as a JSON object, at most [maxBytes] long.
  static Future<Result<Map<String, Object?>>> readObject(Request request, {int maxBytes = _maxBodyBytes}) async {
    try {
      final Object? json = jsonDecode(await request.readAsString(maxLength: maxBytes));
      if (json is Map<String, Object?>) return Result.success(json);
      return const Result.failure(_notObjectMessage);
    } on FormatException {
      return const Result.failure(_invalidJsonMessage);
    } on MaxBodySizeExceeded {
      return const Result.failure(_tooLargeMessage);
    }
  }
}
```

`lib/features/api_server/presentation/routes/notes_routes.dart`

```dart
import 'dart:async';

import 'package:your_app/core/domain/entities/result.dart';
import 'package:your_app/core/domain/entities/result_state.dart';
import 'package:your_app/core/presentation/routes/json_requests.dart';
import 'package:your_app/core/presentation/routes/json_responses.dart';
import 'package:your_app/features/notes/domain/entities/note.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:relic/relic.dart' show RelicRouter, Request, Response, RouteEx, RouterInjectable;

import '../dto/add_note_request_dto.dart';
import '../dto/note_dto.dart';

/// HTTP routes over the use cases of the notes feature.
///
/// Handlers only translate: request → use case → response. The use cases come in as functions, like in a controller.
final class NotesRoutes implements RouterInjectable {
  static const String _notesPath = '/notes';
  static const String _notesKey = 'notes';
  static const String _loadingMessage = 'The notes are still loading';
  static const String _invalidBodyMessage = 'The body must be {"text": "<note text>"}';

  final ValueListenable<ResultState<List<Note>>> Function() _watchNotes;

  final Future<Result<void>> Function(String text) _addNote;

  /// Creates the routes with the use cases they call: `watchNotesUseCase.call`, `addNoteUseCase.call`.
  const NotesRoutes({required this._watchNotes, required this._addNote});

  @override
  void injectIn(RelicRouter router) {
    router
      ..get(_notesPath, _onGetNotes)
      ..post(_notesPath, _onAddNote);
  }

  /// `GET /notes` → `200 {"notes": [...]}`, `503` while loading, `400` with the load error.
  Response _onGetNotes(Request request) => _watchNotes().value.when(
    idle: _loadingResponse,
    loading: _loadingResponse,
    success: _notesResponse,
    failure: JsonResponses.failure,
  );

  /// `POST /notes {"text": "..."}` → `204`, `400` with the message of the use case.
  Future<Response> _onAddNote(Request request) async {
    final Result<Map<String, Object?>> body = await JsonRequests.readObject(request);
    return body.when<FutureOr<Response>>(success: _addNoteFromJson, failure: JsonResponses.failure);
  }

  Future<Response> _addNoteFromJson(Map<String, Object?> json) async {
    final AddNoteRequestDto? dto = AddNoteRequestDto.fromJson(json);
    if (dto == null) return JsonResponses.failure(_invalidBodyMessage);
    final Result<void> result = await _addNote(dto.text);
    return result.when(success: _noContentResponse, failure: JsonResponses.failure);
  }

  Response _loadingResponse() => JsonResponses.unavailable(_loadingMessage);

  Response _notesResponse(List<Note> notes) =>
      JsonResponses.ok(<String, Object?>{_notesKey: notes.map(_noteJson).toList()});

  Response _noContentResponse(void _) => JsonResponses.noContent();

  Map<String, Object?> _noteJson(Note note) => NoteDto.fromEntity(note).toJson();
}
```

`lib/features/api_server/presentation/middleware/api_token_middleware.dart`

```dart
import 'dart:async';

import 'package:your_app/core/presentation/routes/json_responses.dart';
import 'package:relic/relic.dart'
    show AuthorizationHeader, BearerAuthorizationHeader, Handler, HeadersEx, Middleware, Request, Result;

/// Lets a request through only with `Authorization: Bearer <token>` that [isTokenValid] accepts; `401` otherwise.
Middleware apiTokenMiddleware(bool Function(String token) isTokenValid) => _ApiTokenGuard(isTokenValid).wrap;

/// Checks the token before the routes run.
final class _ApiTokenGuard {
  static const String _noTokenMessage = 'Send the token of the app: Authorization: Bearer <token>';

  final bool Function(String token) _isTokenValid;

  const _ApiTokenGuard(this._isTokenValid);

  Handler wrap(Handler next) => _GuardedHandler(next, this).call;

  bool isAllowed(Request request) {
    final AuthorizationHeader? authorization = request.headers.authorization;
    return authorization is BearerAuthorizationHeader && _isTokenValid(authorization.token);
  }

  FutureOr<Result> reject() => JsonResponses.unauthorized(_noTokenMessage);
}

/// [_next] behind the token check of [_guard].
final class _GuardedHandler {
  final Handler _next;

  final _ApiTokenGuard _guard;

  const _GuardedHandler(this._next, this._guard);

  FutureOr<Result> call(Request request) => _guard.isAllowed(request) ? _next(request) : _guard.reject();
}
```

`lib/features/api_server/presentation/di/api_server_di.dart`

```dart
import 'package:your_app/core/presentation/di/core_di.dart';
import 'package:your_app/features/notes/presentation/di/notes_getters.dart';
import 'package:logger/logger.dart';
import 'package:relic/relic.dart' show Middleware, RouterInjectable;
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/api_server_data_source.dart';
import '../../data/data_sources/relic_api_server_data_source.dart';
import '../../data/repositories/api_server_repository_impl.dart';
import '../../domain/repositories/api_server_repository.dart';
import '../../domain/use_cases/check_api_token_use_case.dart';
import '../../domain/use_cases/start_api_server_use_case.dart';
import '../../domain/use_cases/stop_api_server_use_case.dart';
import '../../domain/use_cases/watch_api_server_state_use_case.dart';
import '../middleware/api_token_middleware.dart';
import '../routes/notes_routes.dart';

/// Registers the API server: Relic with the routes over other features' use cases, behind the token check.
///
/// Register it after the features it serves; the server stays off until `startApiServerUseCase()`.
void registerAndInitApiServer() {
  // 1. data sources — the routes call the use cases of other features through their getters
  di.registerLazySingleton<ApiServerDataSource>(
    () => RelicApiServerDataSource(
      routes: <RouterInjectable>[NotesRoutes(watchNotes: watchNotesUseCase.call, addNote: addNoteUseCase.call)],
      middleware: <Middleware>[apiTokenMiddleware(_isTokenValid)],
    ),
    dispose: disposeResource,
  );

  // 2. repositories
  di.registerLazySingleton<ApiServerRepository>(
    () => ApiServerRepositoryImpl(dataSource: di<ApiServerDataSource>(), logger: di<Logger>()),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchApiServerStateUseCase>(() => WatchApiServerStateUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<StartApiServerUseCase>(() => StartApiServerUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<StopApiServerUseCase>(() => StopApiServerUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<CheckApiTokenUseCase>(() => CheckApiTokenUseCase(di<ApiServerRepository>()));
}

/// Looked up per request: the data source is built before the repository the use case needs.
bool _isTokenValid(String token) => di<CheckApiTokenUseCase>()(token);
```

`lib/features/api_server/presentation/widgets/api_server_switch_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/api_server_state.dart';
import '../di/api_server_getters.dart';

/// Turns the API server on and off and shows its port and token.
final class ApiServerSwitchWidget extends WatchingWidget {
  static const String _title = 'Serve over the local network';
  static const String _stoppedText = 'Off';
  static const String _portText = 'Port ';
  static const String _tokenText = ' · token ';

  /// Creates the widget.
  const ApiServerSwitchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiServerState state = watch(watchApiServerStateUseCase()).value;
    return SwitchListTile(
      title: const Text(_title),
      subtitle: SelectableText(_describe(state)),
      value: state is RunningApiServerState,
      onChanged: _onChanged,
    );
  }

  String _describe(ApiServerState state) => switch (state) {
    StoppedApiServerState() => _stoppedText,
    RunningApiServerState(:final int port, :final String token) => '$_portText$port$_tokenText$token',
    FailedApiServerState(:final String message) => message,
  };

  void _onChanged(bool on) {
    if (on) {
      startApiServerUseCase();
    } else {
      stopApiServerUseCase();
    }
  }
}
```

The `_isTokenValid` function in the DI file is looked up per request on purpose: the data source (with the
middleware) is built before the repository that `CheckApiTokenUseCase` needs, so an eager
`checkApiTokenUseCase.call` would create a DI cycle.

## Tests

- Repository with a fake data source: start → `Running` with a token that `isTokenValid` accepts, stop → the
  token stops working, a taken port → `Failed` and a human-readable failure.
- Routes against a real `RelicApiServerDataSource` on `loopbackIPv4:0` with plain functions as use cases and
  `HttpClient` from `dart:io`: 401 without / with a wrong token, the JSON of `GET`, the use case message on 400.
  Use `test()`, not `testWidgets()` — the widget test binding replaces `HttpClient` with a fake.
- The page with `registerAndInitApiServerForTest(FakeApiServerDataSource())`.

See `assets/example_app/test/features/api_server/`.

## Try it

```bash
# in the running example app: the Wi-Fi icon → turn the server on, copy the token
curl -H "Authorization: Bearer <token>" http://<this-computer>.local:8080/notes
curl -H "Authorization: Bearer <token>" -d '{"text": "From the phone"}' http://<this-computer>.local:8080/notes
```
