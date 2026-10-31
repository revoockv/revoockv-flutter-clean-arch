import 'dart:async';

import 'package:example_app/core/presentation/routes/json_responses.dart';
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
