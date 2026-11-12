import 'package:example_app/core/domain/entities/result.dart';
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
