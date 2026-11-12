import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/api_server/data/data_sources/api_server_data_source.dart';
import 'package:example_app/features/api_server/data/repositories/api_server_repository_impl.dart';
import 'package:example_app/features/api_server/domain/repositories/api_server_repository.dart';
import 'package:example_app/features/api_server/domain/use_cases/check_api_token_use_case.dart';
import 'package:example_app/features/api_server/domain/use_cases/start_api_server_use_case.dart';
import 'package:example_app/features/api_server/domain/use_cases/stop_api_server_use_case.dart';
import 'package:example_app/features/api_server/domain/use_cases/watch_api_server_state_use_case.dart';
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

/// Test DI of the API server: the same registrations as `registerAndInitApiServer()`,
/// with [dataSource] instead of the Relic server.
///
/// Keep it in sync with `lib/features/api_server/presentation/di/api_server_di.dart`.
Future<void> registerAndInitApiServerForTest(ApiServerDataSource dataSource) async {
  await di.reset();

  // core — a silent logger
  di.registerSingleton<Logger>(Logger(level: Level.off));

  // 1. data sources — the one the test chose
  di.registerSingleton<ApiServerDataSource>(dataSource, dispose: disposeResource);

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

  await di.allReady();
}
