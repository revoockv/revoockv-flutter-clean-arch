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

They are not Flutter layers, so the project lists them in its `.clean_arch_ignore` (the skill's `docs/linter.md`)
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
2. **Routes get use cases as functions** through the constructor — closures that call the getter:
   `watchNotes: () => watchNotesUseCase()`, never a `.call` tear-off.
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

- `example/lib/features/api_server/domain/entities/api_server_state.dart`
- `example/lib/features/api_server/domain/repositories/api_server_repository.dart`
- `example/lib/features/api_server/domain/use_cases/check_api_token_use_case.dart`
- `example/lib/features/api_server/data/data_sources/api_server_data_source.dart`
- `example/lib/features/api_server/data/data_sources/relic_api_server_data_source.dart`
- `example/lib/features/api_server/data/repositories/api_server_repository_impl.dart`
- `example/lib/core/presentation/routes/json_responses.dart`
- `example/lib/core/presentation/routes/json_requests.dart`
- `example/lib/features/api_server/presentation/routes/notes_routes.dart`
- `example/lib/features/api_server/presentation/middleware/api_token_middleware.dart`
- `example/lib/features/api_server/presentation/di/api_server_di.dart`
- `example/lib/features/api_server/presentation/widgets/api_server_switch_widget.dart`

The `_isTokenValid` function in the DI file is looked up per request on purpose: the data source (with the
middleware) is built before the repository that `CheckApiTokenUseCase` needs, so an eager
`checkApiTokenUseCase` would create a DI cycle.

## Tests

- Repository with a fake data source: start → `Running` with a token that `isTokenValid` accepts, stop → the
  token stops working, a taken port → `Failed` and a human-readable failure.
- Routes against a real `RelicApiServerDataSource` on `loopbackIPv4:0` with plain functions as use cases and
  `HttpClient` from `dart:io`: 401 without / with a wrong token, the JSON of `GET`, the use case message on 400.
  Use `test()`, not `testWidgets()` — the widget test binding replaces `HttpClient` with a fake.
- The page with `registerAndInitApiServerForTest(FakeApiServerDataSource())`.

See `example/test/features/api_server/`.

## Try it

```bash
# in the running example app: the Wi-Fi icon → turn the server on, copy the token
curl -H "Authorization: Bearer <token>" http://<this-computer>.local:8080/notes
curl -H "Authorization: Bearer <token>" -d '{"text": "From the phone"}' http://<this-computer>.local:8080/notes
```
