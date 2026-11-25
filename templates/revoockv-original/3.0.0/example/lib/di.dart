import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/notes/presentation/di/notes_di.dart';
import 'features/pins/presentation/di/pins_di.dart';
import 'features/statistics/presentation/di/statistics_di.dart';

/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();

  // Features that others use come first: notes use pins; statistics use notes and pins.
  registerAndInitPins();
  registerAndInitNotes();
  registerAndInitStatistics();

  await di.allReady();
}
