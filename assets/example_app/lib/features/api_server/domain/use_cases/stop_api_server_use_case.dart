import 'package:example_app/core/domain/entities/result.dart';

import '../repositories/api_server_repository.dart';

/// Action use case: stops serving the app's use cases over the local network.
final class StopApiServerUseCase {
  final ApiServerRepository _repository;

  /// Creates the use case.
  StopApiServerUseCase(this._repository);

  /// Stops the server; does nothing when it already is off.
  Future<Result<void>> call() => _repository.stop();
}
