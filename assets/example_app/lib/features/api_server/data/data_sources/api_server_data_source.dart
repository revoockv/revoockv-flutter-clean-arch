/// An HTTP server on the local network.
abstract interface class ApiServerDataSource {
  /// Starts listening on [port] (`0` = any free port) on every network interface; returns the real port.
  Future<int> start({required int port});

  /// Stops listening; waits for the requests in flight.
  Future<void> stop();
}
