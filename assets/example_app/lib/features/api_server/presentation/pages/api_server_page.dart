import 'package:flutter/material.dart';

import '../widgets/api_server_switch_widget.dart';

/// Settings of the API server: on / off, port and token.
final class ApiServerPage extends StatelessWidget {
  static const String _title = 'API server';

  /// Creates the page.
  const ApiServerPage({super.key});

  /// Pushes the page.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const ApiServerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: const ApiServerSwitchWidget(),
    );
  }
}
