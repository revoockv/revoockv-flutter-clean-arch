import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/in_memory_notes_data_source.dart';
import '../../data/data_sources/notes_data_source.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';

/// The notes feature in the tree, bottom-up: data source → repository → use cases.
///
/// Created lazily on the first `context.read<…>()`; the data source is disposed with the widget.
final class NotesProvidersWidget extends StatelessWidget {
  /// The widgets below.
  final Widget child;

  /// Creates the storage (tests pass a fake one).
  final NotesDataSource Function() createDataSource;

  /// Creates the providers.
  const NotesProvidersWidget({
    required this.child,
    this.createDataSource = _createInMemoryDataSource,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<NotesDataSource>(create: _createDataSource, dispose: _disposeDataSource),
        RepositoryProvider<NotesRepository>(create: _createRepository),
        RepositoryProvider<WatchNotesUseCase>(create: _createWatchNotesUseCase),
        RepositoryProvider<AddNoteUseCase>(create: _createAddNoteUseCase),
        RepositoryProvider<DeleteNoteUseCase>(create: _createDeleteNoteUseCase),
      ],
      child: child,
    );
  }

  static NotesDataSource _createInMemoryDataSource() => InMemoryNotesDataSource();

  NotesDataSource _createDataSource(BuildContext context) => createDataSource();

  static void _disposeDataSource(NotesDataSource dataSource) => dataSource.dispose();

  static NotesRepository _createRepository(BuildContext context) =>
      NotesRepositoryImpl(dataSource: context.read<NotesDataSource>(), logger: context.read<Logger>());

  static WatchNotesUseCase _createWatchNotesUseCase(BuildContext context) =>
      WatchNotesUseCase(context.read<NotesRepository>());

  static AddNoteUseCase _createAddNoteUseCase(BuildContext context) => AddNoteUseCase(context.read<NotesRepository>());

  static DeleteNoteUseCase _createDeleteNoteUseCase(BuildContext context) =>
      DeleteNoteUseCase(context.read<NotesRepository>());
}
