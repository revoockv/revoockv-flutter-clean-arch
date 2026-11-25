import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';

/// Registers the statistics feature after the notes and the pins it counts: its repository waits for theirs.
void registerAndInitStatistics() {
  // 1. data sources — none: the statistics use the notes and the pins features

  // 2. repositories — over the other features' repositories, once they are ready
  di.registerSingletonWithDependencies<StatisticsRepository>(
    () => StatisticsRepositoryImpl(notes: di<NotesRepository>(), pins: di<PinsRepository>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[NotesRepository, PinsRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchNotesStatisticsUseCase>(() => WatchNotesStatisticsUseCase(di<StatisticsRepository>()));
}
