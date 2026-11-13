import 'dart:async';

import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/app_database.dart';
import '../../data/data_sources/in_memory_app_database.dart';
import '../../domain/entities/disposable_resource.dart';

/// GetIt `dispose:` callback: calls our [DisposableResource.dispose] if [instance] owns resources.
FutureOr<void> disposeResource(Object instance) =>
    instance is DisposableResource ? instance.dispose() : null;

/// Registers app-wide services used by every feature: the logger and the database.
void registerAndInitCore() {
  di.registerSingleton<Logger>(Logger());
  di.registerLazySingleton<AppDatabase>(InMemoryAppDatabase.new, dispose: disposeResource);
}
