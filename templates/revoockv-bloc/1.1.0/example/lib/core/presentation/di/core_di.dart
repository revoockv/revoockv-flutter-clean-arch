import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/app_database.dart';
import '../../data/data_sources/in_memory_app_database.dart';

/// App-wide services every feature reads from the tree: the logger and the database.
final class CoreProvidersWidget extends StatelessWidget {
  /// The widgets below; they find the services with `context.read<…>()`.
  final Widget child;

  /// Creates the logger (tests pass a silent one).
  final Logger Function() createLogger;

  /// Creates the database (tests pass one without latency).
  final AppDatabase Function() createDatabase;

  /// Creates the providers.
  const CoreProvidersWidget({
    required this.child,
    this.createLogger = _createLogger,
    this.createDatabase = _createDatabase,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<Logger>(create: _createLoggerFromContext),
        RepositoryProvider<AppDatabase>(create: _createDatabaseFromContext, dispose: _closeDatabase),
      ],
      child: child,
    );
  }

  static Logger _createLogger() => Logger();

  static AppDatabase _createDatabase() => InMemoryAppDatabase();

  Logger _createLoggerFromContext(BuildContext context) => createLogger();

  AppDatabase _createDatabaseFromContext(BuildContext context) => createDatabase();

  static void _closeDatabase(AppDatabase database) => database.close();
}
