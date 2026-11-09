import 'dart:io';

import 'package:example_app/features/api_server/data/data_sources/api_server_data_source.dart';

/// Pretends to listen: start returns the port it was given, nothing is bound.
final class FakeApiServerDataSource implements ApiServerDataSource {
  /// Whether the fake "listens".
  bool listening = false;

  @override
  Future<int> start({required int port}) async {
    listening = true;
    return port;
  }

  @override
  Future<void> stop() async => listening = false;
}

/// The port is always taken.
final class BusyPortApiServerDataSource implements ApiServerDataSource {
  @override
  Future<int> start({required int port}) async => throw const SocketException('Address already in use');

  @override
  Future<void> stop() async {}
}
