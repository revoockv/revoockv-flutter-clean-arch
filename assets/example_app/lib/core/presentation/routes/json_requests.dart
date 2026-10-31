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
