import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';

/// The statistics: a progress indicator while loading, the load error, or the tiles.
///
/// Dumb: the tiles come built (each with its own wrapper), the texts from above.
final class StatisticsListWidget extends StatelessWidget {
  /// Whether the first numbers have not arrived yet.
  final bool isLoading;

  /// The text of the load error, `null` when the numbers are loaded.
  final String? failureText;

  /// The tiles, in their order.
  final List<Widget> tiles;

  /// Creates the list.
  const StatisticsListWidget({required this.isLoading, required this.failureText, required this.tiles, super.key});

  @override
  Widget build(BuildContext context) {
    final String? failure = failureText;
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (failure != null) return Center(child: Text(failure));
    return ListView(padding: const EdgeInsets.all(AppTheme.spacingMedium), children: tiles);
  }
}
