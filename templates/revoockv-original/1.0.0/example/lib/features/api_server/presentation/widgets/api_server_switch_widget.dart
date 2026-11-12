import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/api_server_state.dart';
import '../di/api_server_getters.dart';

/// Turns the API server on and off and shows its port and token.
final class ApiServerSwitchWidget extends WatchingWidget {
  static const String _title = 'Serve over the local network';
  static const String _stoppedText = 'Off';
  static const String _portText = 'Port ';
  static const String _tokenText = ' · token ';

  /// Creates the widget.
  const ApiServerSwitchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiServerState state = watch(watchApiServerStateUseCase()).value;
    return SwitchListTile(
      title: const Text(_title),
      subtitle: SelectableText(_describe(state)),
      value: state is RunningApiServerState,
      onChanged: _onChanged,
    );
  }

  String _describe(ApiServerState state) => switch (state) {
    StoppedApiServerState() => _stoppedText,
    RunningApiServerState(:final int port, :final String token) => '$_portText$port$_tokenText$token',
    FailedApiServerState(:final String message) => message,
  };

  void _onChanged(bool on) {
    if (on) {
      startApiServerUseCase();
    } else {
      stopApiServerUseCase();
    }
  }
}
