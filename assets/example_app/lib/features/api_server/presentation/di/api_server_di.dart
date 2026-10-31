import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/presentation/di/notes_getters.dart';
import 'package:logger/logger.dart';
import 'package:relic/relic.dart' show Middleware, RouterInjectable;
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/api_server_data_source.dart';
import '../../data/data_sources/relic_api_server_data_source.dart';
import '../../data/repositories/api_server_repository_impl.dart';
import '../../domain/repositories/api_server_repository.dart';
import '../../domain/use_cases/check_api_token_use_case.dart';
import '../../domain/use_cases/start_api_server_use_case.dart';
import '../../domain/use_cases/stop_api_server_use_case.dart';
import '../../domain/use_cases/watch_api_server_state_use_case.dart';
import '../middleware/api_token_middleware.dart';
import '../routes/notes_routes.dart';

/// Registers the API server: Relic with the routes over other features' use cases, behind the token check.
///
/// Register it after the features it serves; the server stays off until `startApiServerUseCase()`.
void registerAndInitApiServer() {
  // 1. data sources — the routes call the use cases of other features through their getters
  di.registerLazySingleton<ApiServerDataSource>(
    () => RelicApiServerDataSource(
      routes: <RouterInjectable>[NotesRoutes(watchNotes: watchNotesUseCase.call, addNote: addNoteUseCase.call)],
      middleware: <Middleware>[apiTokenMiddleware(_isTokenValid)],
    ),
    dispose: disposeResource,
  );

  // 2. repositories
  di.registerLazySingleton<ApiServerRepository>(
    () => ApiServerRepositoryImpl(dataSource: di<ApiServerDataSource>(), logger: di<Logger>()),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchApiServerStateUseCase>(() => WatchApiServerStateUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<StartApiServerUseCase>(() => StartApiServerUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<StopApiServerUseCase>(() => StopApiServerUseCase(di<ApiServerRepository>()));
  di.registerLazySingleton<CheckApiTokenUseCase>(() => CheckApiTokenUseCase(di<ApiServerRepository>()));
}

/// Looked up per request: the data source is built before the repository the use case needs.
bool _isTokenValid(String token) => di<CheckApiTokenUseCase>()(token);
