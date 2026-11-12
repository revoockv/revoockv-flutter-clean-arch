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
