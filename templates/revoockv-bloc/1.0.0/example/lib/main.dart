import 'package:flutter/material.dart';

import 'core/presentation/pages/home_page.dart';
import 'core/presentation/theme.dart';
import 'di.dart';

void main() {
  runApp(const ExampleAppWidget());
}

/// Root widget of the example app.
final class ExampleAppWidget extends StatelessWidget {
  /// Creates the app.
  const ExampleAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProvidersWidget(
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: AppTheme.seedColor),
        home: const HomePage(),
      ),
    );
  }
}
