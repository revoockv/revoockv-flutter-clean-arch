import 'package:example_app/core/presentation/di/core_di.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/presentation/di/notes_di.dart';
import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// The notes page with the app's real providers, a silent logger and [dataSource] as the storage.
Widget notesTestApp(NotesDataSource dataSource) => CoreProvidersWidget(
      createLogger: () => Logger(level: Level.off),
      child: NotesProvidersWidget(
        createDataSource: () => dataSource,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
