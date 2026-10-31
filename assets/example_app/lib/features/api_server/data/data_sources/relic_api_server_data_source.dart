import 'dart:io';

import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:relic/relic.dart' show Middleware, RelicApp, RelicAppIOServeEx, RelicServer, RouterInjectable;

import 'api_server_data_source.dart';

/// Serves [_routes] behind [_middleware] with Relic; a new `RelicApp` on every start.
final class RelicApiServerDataSource implements ApiServerDataSource, DisposableResource {
  static const String _rootPath = '/';

  final List<RouterInjectable> _routes;

  final List<Middleware> _middleware;

  final InternetAddress _address;

  RelicApp? _app;

  /// Creates the data source; [_address] defaults to every IPv4 interface, so phones on the same Wi-Fi reach it.
  RelicApiServerDataSource({required this._routes, required this._middleware, InternetAddress? address})
    : _address = address ?? InternetAddress.anyIPv4;

  @override
  Future<int> start({required int port}) async {
    final RelicApp app = RelicApp();
    for (final Middleware middleware in _middleware) {
      app.use(_rootPath, middleware);
    }
    _routes.forEach(app.inject);
    final RelicServer server = await app.serve(address: _address, port: port);
    _app = app;
    return server.port;
  }

  @override
  Future<void> stop() async {
    await _app?.close();
    _app = null;
  }

  /// Stops the server. Called by DI only.
  @override
  Future<void> dispose() => stop();
}
