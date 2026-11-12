import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/database_statistics_data_source.dart';
import '../../data/data_sources/statistics_data_source.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';

/// Registers the statistics feature and starts its async initialization.
void registerAndInitStatistics() {
  // 1. data sources — over the app's database (core)
  di.registerLazySingleton<StatisticsDataSource>(() => DatabaseStatisticsDataSource(database: di<AppDatabase>()));

  // 2. repositories — async init: subscribes to the data source
  di.registerSingletonAsync<StatisticsRepository>(
    () => StatisticsRepositoryImpl(dataSource: di<StatisticsDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchNotesStatisticsUseCase>(
    () => WatchNotesStatisticsUseCase(di<StatisticsRepository>()),
  );
}
