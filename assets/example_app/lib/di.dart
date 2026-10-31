import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/api_server/presentation/di/api_server_di.dart';
import 'features/notes/presentation/di/notes_di.dart';

/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();

  registerAndInitNotes();
  registerAndInitApiServer();

  await di.allReady();
}
