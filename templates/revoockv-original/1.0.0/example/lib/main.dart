import 'package:flutter/material.dart';

import 'core/presentation/theme.dart';
import 'di.dart';
import 'features/notes/presentation/pages/notes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await registerAndInit();

  runApp(const ExampleAppWidget());
}

/// Root widget of the example app.
final class ExampleAppWidget extends StatelessWidget {
  /// Creates the app.
  const ExampleAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: AppTheme.seedColor),
      home: const NotesPage(),
    );
  }
}
