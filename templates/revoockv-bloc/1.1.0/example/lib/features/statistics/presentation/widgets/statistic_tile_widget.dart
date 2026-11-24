import 'package:flutter/material.dart';

/// One number with its label.
final class StatisticTileWidget extends StatelessWidget {
  /// What the number counts.
  final String label;

  /// The number.
  final int value;

  /// Creates the tile.
  const StatisticTileWidget({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
