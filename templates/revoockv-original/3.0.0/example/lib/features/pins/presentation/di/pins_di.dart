import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/database_pins_data_source.dart';
import '../../data/data_sources/pins_data_source.dart';
import '../../data/repositories/pins_repository_impl.dart';
import '../../domain/repositories/pins_repository.dart';
import '../../domain/use_cases/toggle_pin_use_case.dart';
import '../../domain/use_cases/watch_pinned_notes_use_case.dart';

/// Registers the pins feature; it depends on no other feature, so the notes feature may use it.
void registerAndInitPins() {
  // 1. data sources — over the app's database (core)
  di.registerLazySingleton<PinsDataSource>(() => DatabasePinsDataSource(database: di<AppDatabase>()));

  // 2. repositories — async init: subscribes to the data source
  di.registerSingletonAsync<PinsRepository>(
    () => PinsRepositoryImpl(dataSource: di<PinsDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchPinnedNotesUseCase>(() => WatchPinnedNotesUseCase(di<PinsRepository>()));
  di.registerLazySingleton<TogglePinUseCase>(() => TogglePinUseCase(di<PinsRepository>()));
}
