import 'package:example_app/core/data/data_sources/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/database_pins_data_source.dart';
import '../../data/data_sources/pins_data_source.dart';
import '../../data/repositories/pins_repository_impl.dart';
import '../../domain/repositories/pins_repository.dart';
import '../../domain/use_cases/toggle_pin_use_case.dart';
import '../../domain/use_cases/watch_pinned_notes_use_case.dart';

/// The pins feature in the tree, bottom-up: data source → repository → use cases.
///
/// It depends on no other feature; it sits above the features that use it (notes, statistics).
final class PinsProvidersWidget extends StatelessWidget {
  /// The widgets below.
  final Widget child;

  /// Creates the storage over the database (tests pass a fake one).
  final PinsDataSource Function(AppDatabase database) createDataSource;

  /// Creates the providers.
  const PinsProvidersWidget({required this.child, this.createDataSource = _createDatabaseDataSource, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<PinsDataSource>(create: _createDataSource),
        RepositoryProvider<PinsRepository>(create: _createRepository),
        RepositoryProvider<WatchPinnedNotesUseCase>(create: _createWatchPinnedNotesUseCase),
        RepositoryProvider<TogglePinUseCase>(create: _createTogglePinUseCase),
      ],
      child: child,
    );
  }

  static PinsDataSource _createDatabaseDataSource(AppDatabase database) => DatabasePinsDataSource(database: database);

  PinsDataSource _createDataSource(BuildContext context) => createDataSource(context.read<AppDatabase>());

  static PinsRepository _createRepository(BuildContext context) =>
      PinsRepositoryImpl(dataSource: context.read<PinsDataSource>(), logger: context.read<Logger>());

  static WatchPinnedNotesUseCase _createWatchPinnedNotesUseCase(BuildContext context) =>
      WatchPinnedNotesUseCase(context.read<PinsRepository>());

  static TogglePinUseCase _createTogglePinUseCase(BuildContext context) =>
      TogglePinUseCase(context.read<PinsRepository>());
}
