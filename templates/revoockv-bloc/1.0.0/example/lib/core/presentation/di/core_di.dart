import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

/// App-wide services every feature reads from the tree: the logger.
final class CoreProvidersWidget extends StatelessWidget {
  /// The widgets below; they find the services with `context.read<…>()`.
  final Widget child;

  /// Creates the logger (tests pass a silent one).
  final Logger Function() createLogger;

  /// Creates the providers.
  const CoreProvidersWidget({required this.child, this.createLogger = _createLogger, super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Logger>(create: _createLoggerFromContext, child: child);
  }

  static Logger _createLogger() => Logger();

  Logger _createLoggerFromContext(BuildContext context) => createLogger();
}
