import 'package:flutter/material.dart';

/// Values shared by more than one feature: spacing, sizes, colors.
///
/// A value used by a single widget stays a private `static const` of that widget.
final class AppTheme {
  /// Small gap between related elements.
  static const double spacingSmall = 8;

  /// Default padding of screens and cards.
  static const double spacingMedium = 16;

  /// Large gap between sections.
  static const double spacingLarge = 24;

  /// Seed color of the app color scheme.
  static const Color seedColor = Colors.indigo;

  const AppTheme._();
}
