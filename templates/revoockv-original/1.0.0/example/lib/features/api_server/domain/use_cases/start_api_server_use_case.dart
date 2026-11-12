import 'package:example_app/core/domain/entities/result.dart';

import '../repositories/api_server_repository.dart';

/// Action use case: starts serving the app's use cases over the local network.
final class StartApiServerUseCase {
  final ApiServerRepository _repository;

  /// Creates the use case.
  StartApiServerUseCase(this._repository);

  /// Starts the server; does nothing when it already runs.
  Future<Result<void>> call() => _repository.start();
}
