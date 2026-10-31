import '../repositories/api_server_repository.dart';

/// Query use case: is a request allowed to call the app's use cases?
final class CheckApiTokenUseCase {
  final ApiServerRepository _repository;

  /// Creates the use case.
  CheckApiTokenUseCase(this._repository);

  /// Whether [token] is the token of the running server; always `false` when it is off.
  bool call(String token) => _repository.isTokenValid(token);
}
