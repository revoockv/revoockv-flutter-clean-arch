import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/in_memory_notes_data_source.dart';
import '../../data/data_sources/notes_data_source.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';

/// Registers the notes feature and starts its async initialization.
///
/// Plug the feature into any app with this single call; `di.allReady()` waits for its `init()`.
void registerAndInitNotes() {
  // 1. data sources
  di.registerLazySingleton<NotesDataSource>(InMemoryNotesDataSource.new, dispose: disposeResource);

  // 2. repositories — async init: subscribes to the data source
  di.registerSingletonAsync<NotesRepository>(
    () => NotesRepositoryImpl(dataSource: di<NotesDataSource>(), logger: di<Logger>()).init(),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchNotesUseCase>(() => WatchNotesUseCase(di<NotesRepository>()));
  di.registerLazySingleton<AddNoteUseCase>(() => AddNoteUseCase(di<NotesRepository>()));
  di.registerLazySingleton<DeleteNoteUseCase>(() => DeleteNoteUseCase(di<NotesRepository>()));
}
