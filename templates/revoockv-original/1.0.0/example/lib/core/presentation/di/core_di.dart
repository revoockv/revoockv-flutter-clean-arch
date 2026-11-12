import 'dart:async';

import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/disposable_resource.dart';

/// GetIt `dispose:` callback: calls our [DisposableResource.dispose] if [instance] owns resources.
FutureOr<void> disposeResource(Object instance) =>
    instance is DisposableResource ? instance.dispose() : null;

/// Registers app-wide services used by every feature.
void registerAndInitCore() {
  di.registerSingleton<Logger>(Logger());
}
