import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/data/data_sources/database_notes_data_source.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/notes/domain/use_cases/add_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/delete_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/update_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/watch_notes_use_case.dart';
import 'package:example_app/features/statistics/data/data_sources/database_statistics_data_source.dart';
import 'package:example_app/features/statistics/data/data_sources/statistics_data_source.dart';
import 'package:example_app/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:example_app/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:example_app/features/statistics/domain/use_cases/watch_notes_statistics_use_case.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

/// Test DI of the app: the same registrations as `registerAndInit()`, with a silent logger, a database without
/// latency, and [notes] / [statistics] instead of the real data sources when given.
///
/// Keep it in sync with `lib/di.dart` and the features' `*_di.dart`.
Future<void> registerAndInitForTest({NotesDataSource? notes, StatisticsDataSource? statistics}) async {
  await di.reset();

  // core
  di.registerSingleton<Logger>(Logger(level: Level.off));
  di.registerSingleton<AppDatabase>(InMemoryAppDatabase(latency: Duration.zero), dispose: disposeResource);

  // notes
  di.registerSingleton<NotesDataSource>(notes ?? DatabaseNotesDataSource(database: di<AppDatabase>()));
  di.registerSingletonAsync<NotesRepository>(
    () => NotesRepositoryImpl(dataSource: di<NotesDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );
  di.registerLazySingleton<WatchNotesUseCase>(() => WatchNotesUseCase(di<NotesRepository>()));
  di.registerLazySingleton<AddNoteUseCase>(() => AddNoteUseCase(di<NotesRepository>()));
  di.registerLazySingleton<UpdateNoteUseCase>(() => UpdateNoteUseCase(di<NotesRepository>()));
  di.registerLazySingleton<DeleteNoteUseCase>(() => DeleteNoteUseCase(di<NotesRepository>()));

  // statistics
  di.registerSingleton<StatisticsDataSource>(statistics ?? DatabaseStatisticsDataSource(database: di<AppDatabase>()));
  di.registerSingletonAsync<StatisticsRepository>(
    () => StatisticsRepositoryImpl(dataSource: di<StatisticsDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );
  di.registerLazySingleton<WatchNotesStatisticsUseCase>(() => WatchNotesStatisticsUseCase(di<StatisticsRepository>()));

  await di.allReady();
}
