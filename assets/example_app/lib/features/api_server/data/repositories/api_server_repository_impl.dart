import 'dart:convert';
import 'dart:math';

import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/api_server_state.dart';
import '../../domain/repositories/api_server_repository.dart';
import '../data_sources/api_server_data_source.dart';

/// Starts and stops the server, owns its state and the token of the running server.
final class ApiServerRepositoryImpl implements ApiServerRepository, DisposableResource {
  /// Port of the server unless DI or a test gives another.
  static const int _defaultPort = 8080;

  /// Random bytes in a token (256 bits).
  static const int _tokenBytes = 32;

  /// Largest value of one random byte, exclusive.
  static const int _byteRange = 256;

  /// Padding that base64Url adds and a token does not need.
  static const String _base64Padding = '=';

  static const String _startFailedMessage = 'Could not start the server — is the port taken?';
  static const String _stopFailedMessage = 'Could not stop the server';

  static const String _startSuccessLog = 'StartApiServer: success — listening on port ';
  static const String _startSkippedLog = 'StartApiServer: skipped — already running';
  static const String _startFailureLog = 'StartApiServer: failure — ';
  static const String _stopSuccessLog = 'StopApiServer: success — stopped';
  static const String _stopFailureLog = 'StopApiServer: failure — ';
  static const String _disposeLog = 'ApiServerRepository dispose: server stopped';

  final ApiServerDataSource _dataSource;

  final Logger _logger;

  final int _port;

  final Random _random = Random.secure();

  final ValueNotifier<ApiServerState> _state = ValueNotifier<ApiServerState>(const StoppedApiServerState());

  /// Creates the repository; once started the server listens on [_port] (8080 by default, `0` = any free port).
  ApiServerRepositoryImpl({required this._dataSource, required this._logger, this._port = _defaultPort});

  /// Stops the server and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await stop();
    _state.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ApiServerState> watchState() => _state;

  @override
  Future<Result<void>> start() async {
    if (_state.value is RunningApiServerState) {
      _logger.w(_startSkippedLog);
      return Result.ok;
    }
    try {
      final int port = await _dataSource.start(port: _port);
      _state.value = RunningApiServerState(port: port, token: _newToken());
      _logger.i('$_startSuccessLog$port');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_startFailureLog$e');
      _state.value = const FailedApiServerState(_startFailedMessage);
      return const Result.failure(_startFailedMessage);
    }
  }

  @override
  Future<Result<void>> stop() async {
    if (_state.value is! RunningApiServerState) return Result.ok;
    try {
      await _dataSource.stop();
      _state.value = const StoppedApiServerState();
      _logger.i(_stopSuccessLog);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_stopFailureLog$e');
      return const Result.failure(_stopFailedMessage);
    }
  }

  @override
  bool isTokenValid(String token) {
    final ApiServerState state = _state.value;
    return state is RunningApiServerState && _sameText(state.token, token);
  }

  String _newToken() => base64Url.encode(List<int>.generate(_tokenBytes, _randomByte)).replaceAll(_base64Padding, '');

  int _randomByte(int _) => _random.nextInt(_byteRange);

  /// Compares in constant time, so the time of an answer tells nothing about the token.
  bool _sameText(String a, String b) {
    if (a.length != b.length) return false;
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
