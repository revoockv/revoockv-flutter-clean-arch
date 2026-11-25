import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/presentation/di/notes_di.dart';
import 'package:example_app/features/pins/data/data_sources/pins_data_source.dart';
import 'package:example_app/features/pins/presentation/di/pins_di.dart';
import 'package:example_app/features/statistics/presentation/di/statistics_di.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// [home] under the app's real providers with a silent logger, a database without latency, and [notes] / [pins]
/// instead of the real data sources when given.
Widget testApp(Widget home, {NotesDataSource? notes, PinsDataSource? pins}) {
  final Widget withStatistics = StatisticsProvidersWidget(child: MaterialApp(home: home));
  final Widget withNotes = notes == null
      ? NotesProvidersWidget(child: withStatistics)
      : NotesProvidersWidget(createDataSource: (AppDatabase _) => notes, child: withStatistics);
  final Widget withPins = pins == null
      ? PinsProvidersWidget(child: withNotes)
      : PinsProvidersWidget(createDataSource: (AppDatabase _) => pins, child: withNotes);
  return CoreProvidersWidget(
    createLogger: () => Logger(level: Level.off),
    createDatabase: () => InMemoryAppDatabase(latency: Duration.zero),
    child: withPins,
  );
}
