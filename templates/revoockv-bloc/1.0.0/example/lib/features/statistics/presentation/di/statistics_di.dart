import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/database_statistics_data_source.dart';
import '../../data/data_sources/statistics_data_source.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';

/// The statistics feature in the tree, bottom-up: data source → repository → use case.
final class StatisticsProvidersWidget extends StatelessWidget {
  /// The widgets below.
  final Widget child;

  /// Creates the storage over the database (tests pass a fake one).
  final StatisticsDataSource Function(AppDatabase database) createDataSource;

  /// Creates the providers.
  const StatisticsProvidersWidget({
    required this.child,
    this.createDataSource = _createDatabaseDataSource,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<StatisticsDataSource>(create: _createDataSource),
        RepositoryProvider<StatisticsRepository>(create: _createRepository),
        RepositoryProvider<WatchNotesStatisticsUseCase>(create: _createWatchNotesStatisticsUseCase),
      ],
      child: child,
    );
  }

  static StatisticsDataSource _createDatabaseDataSource(AppDatabase database) =>
      DatabaseStatisticsDataSource(database: database);

  StatisticsDataSource _createDataSource(BuildContext context) => createDataSource(context.read<AppDatabase>());

  static StatisticsRepository _createRepository(BuildContext context) =>
      StatisticsRepositoryImpl(dataSource: context.read<StatisticsDataSource>(), logger: context.read<Logger>());

  static WatchNotesStatisticsUseCase _createWatchNotesStatisticsUseCase(BuildContext context) =>
      WatchNotesStatisticsUseCase(context.read<StatisticsRepository>());
}
