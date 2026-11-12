import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/notes/domain/use_cases/add_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/delete_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/watch_notes_use_case.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

/// Test DI of the notes feature: the same registrations as `registerAndInitNotes()`,
/// with [dataSource] instead of the real storage.
///
/// Keep it in sync with `lib/features/notes/presentation/di/notes_di.dart`.
Future<void> registerAndInitNotesForTest(NotesDataSource dataSource) async {
  await di.reset();

  // core — a silent logger
  di.registerSingleton<Logger>(Logger(level: Level.off));

  // 1. data sources — the one the test chose
  di.registerSingleton<NotesDataSource>(dataSource, dispose: disposeResource);

  // 2. repositories
  di.registerSingletonAsync<NotesRepository>(
    () => NotesRepositoryImpl(dataSource: di<NotesDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchNotesUseCase>(() => WatchNotesUseCase(di<NotesRepository>()));
  di.registerLazySingleton<AddNoteUseCase>(() => AddNoteUseCase(di<NotesRepository>()));
  di.registerLazySingleton<DeleteNoteUseCase>(() => DeleteNoteUseCase(di<NotesRepository>()));

  await di.allReady();
}
