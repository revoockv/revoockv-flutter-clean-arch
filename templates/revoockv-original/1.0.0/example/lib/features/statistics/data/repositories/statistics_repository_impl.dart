import 'dart:async';

import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/note_facts.dart';
import '../../domain/entities/notes_statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../data_sources/statistics_data_source.dart';
import '../models/note_facts_model.dart';

/// Statistics repository: counts the notes on every change into a private [ValueNotifier] of [ResultState].
final class StatisticsRepositoryImpl implements StatisticsRepository, DisposableResource {
  /// Message shown when the statistics cannot be loaded.
  static const String _loadFailedMessage = 'Could not load the statistics';

  static const String _initLog = 'StatisticsRepository init: subscribed to notes';
  static const String _disposeLog = 'StatisticsRepository dispose: unsubscribed';
  static const String _watchFailureLog = 'WatchNotesStatistics: failure — ';

  final StatisticsDataSource _dataSource;

  final Logger _logger;

  final DateTime Function() _now;

  final ValueNotifier<ResultState<NotesStatistics>> _statistics =
      ValueNotifier<ResultState<NotesStatistics>>(ResultState.loading);

  StreamSubscription<List<NoteFactsModel>>? _sub;

  /// Creates the repository; `now` is the clock that says which day is today.
  StatisticsRepositoryImpl({required this._dataSource, required this._logger, this._now = DateTime.now});

  /// Subscribes to the data source; returns this for `registerSingletonAsync`.
  Future<StatisticsRepositoryImpl> init() async {
    _sub ??= _dataSource.watchNoteFacts().listen(_onFacts, onError: _onError);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _statistics.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ResultState<NotesStatistics>> watchNotesStatistics() => _statistics;

  void _onFacts(List<NoteFactsModel> models) {
    final NotesStatistics statistics = NotesStatistics.of(models.map(_toEntity).toList(), now: _now());
    _statistics.value = ResultState.success(statistics);
  }

  void _onError(Object error) {
    _logger.e('$_watchFailureLog$error');
    _statistics.value = const ResultState.failure(_loadFailedMessage);
  }

  static NoteFacts _toEntity(NoteFactsModel model) => model.toEntity();
}
