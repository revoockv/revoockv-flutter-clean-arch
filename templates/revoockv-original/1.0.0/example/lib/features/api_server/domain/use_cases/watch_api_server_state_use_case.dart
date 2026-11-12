import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/api_server_state.dart';
import '../repositories/api_server_repository.dart';

/// Watch use case: whether the server runs, on which port, with which token.
final class WatchApiServerStateUseCase {
  final ApiServerRepository _repository;

  /// Creates the use case.
  WatchApiServerStateUseCase(this._repository);

  /// Returns the live state of the server; the same instance on every call.
  ValueListenable<ApiServerState> call() => _repository.watchState();
}
