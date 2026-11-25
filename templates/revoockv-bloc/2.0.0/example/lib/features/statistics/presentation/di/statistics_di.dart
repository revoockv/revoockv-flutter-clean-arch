import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/use_cases/watch_notes_statistics_use_case.dart';

/// The statistics feature in the tree: a repository over the notes and the pins features, then the use case.
///
/// It sits below `NotesProvidersWidget` and `PinsProvidersWidget`: the statistics use both.
final class StatisticsProvidersWidget extends StatelessWidget {
  /// The widgets below.
  final Widget child;

  /// Creates the providers.
  const StatisticsProvidersWidget({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<StatisticsRepository>(create: _createRepository),
        RepositoryProvider<WatchNotesStatisticsUseCase>(create: _createWatchNotesStatisticsUseCase),
      ],
      child: child,
    );
  }

  static StatisticsRepository _createRepository(BuildContext context) => StatisticsRepositoryImpl(
    notes: context.read<NotesRepository>(),
    pins: context.read<PinsRepository>(),
    logger: context.read<Logger>(),
  );

  static WatchNotesStatisticsUseCase _createWatchNotesStatisticsUseCase(BuildContext context) =>
      WatchNotesStatisticsUseCase(context.read<StatisticsRepository>());
}
