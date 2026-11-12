import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/database_notes_data_source.dart';
import '../../data/data_sources/notes_data_source.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/update_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';

/// The notes feature in the tree, bottom-up: data source → repository → use cases.
///
/// Created lazily on the first `context.read<…>()`; the data source works over the app's database (core).
final class NotesProvidersWidget extends StatelessWidget {
  /// The widgets below.
  final Widget child;

  /// Creates the storage over the database (tests pass a fake one).
  final NotesDataSource Function(AppDatabase database) createDataSource;

  /// Creates the providers.
  const NotesProvidersWidget({
    required this.child,
    this.createDataSource = _createDatabaseDataSource,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<NotesDataSource>(create: _createDataSource),
        RepositoryProvider<NotesRepository>(create: _createRepository),
        RepositoryProvider<WatchNotesUseCase>(create: _createWatchNotesUseCase),
        RepositoryProvider<AddNoteUseCase>(create: _createAddNoteUseCase),
        RepositoryProvider<UpdateNoteUseCase>(create: _createUpdateNoteUseCase),
        RepositoryProvider<DeleteNoteUseCase>(create: _createDeleteNoteUseCase),
      ],
      child: child,
    );
  }

  static NotesDataSource _createDatabaseDataSource(AppDatabase database) => DatabaseNotesDataSource(database: database);

  NotesDataSource _createDataSource(BuildContext context) => createDataSource(context.read<AppDatabase>());

  static NotesRepository _createRepository(BuildContext context) =>
      NotesRepositoryImpl(dataSource: context.read<NotesDataSource>(), logger: context.read<Logger>());

  static WatchNotesUseCase _createWatchNotesUseCase(BuildContext context) =>
      WatchNotesUseCase(context.read<NotesRepository>());

  static AddNoteUseCase _createAddNoteUseCase(BuildContext context) => AddNoteUseCase(context.read<NotesRepository>());

  static UpdateNoteUseCase _createUpdateNoteUseCase(BuildContext context) =>
      UpdateNoteUseCase(context.read<NotesRepository>());

  static DeleteNoteUseCase _createDeleteNoteUseCase(BuildContext context) =>
      DeleteNoteUseCase(context.read<NotesRepository>());
}
