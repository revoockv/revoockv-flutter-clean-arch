import 'package:flutter/widgets.dart';

import 'core/presentation/di/core_di.dart';
import 'features/notes/presentation/di/notes_di.dart';
import 'features/statistics/presentation/di/statistics_di.dart';

/// Every provider of the app, outermost first: core, then one widget per feature.
final class AppProvidersWidget extends StatelessWidget {
  /// The app below the providers.
  final Widget child;

  /// Creates the providers.
  const AppProvidersWidget({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return CoreProvidersWidget(
      child: NotesProvidersWidget(
        child: StatisticsProvidersWidget(child: child),
      ),
    );
  }
}
