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
