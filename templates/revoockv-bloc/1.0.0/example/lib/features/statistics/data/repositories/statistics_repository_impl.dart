import 'dart:async';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/note_facts.dart';
import '../../domain/entities/notes_statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../data_sources/statistics_data_source.dart';
import '../models/note_facts_model.dart';

/// Statistics repository: counts the notes on every change; a stream error becomes a failure.
final class StatisticsRepositoryImpl implements StatisticsRepository {
  /// Message shown when the statistics cannot be loaded.
  static const String _loadFailedMessage = 'Could not load the statistics';

  static const String _watchFailureLog = 'WatchNotesStatistics: failure — ';

  final StatisticsDataSource _dataSource;

  final Logger _logger;

  final DateTime Function() _now;

  /// Creates the repository; `now` is the clock that says which day is today.
  StatisticsRepositoryImpl({required this._dataSource, required this._logger, this._now = DateTime.now});

  @override
  Stream<Result<NotesStatistics>> watchNotesStatistics() => _dataSource.watchNoteFacts().transform(
        StreamTransformer<List<NoteFactsModel>, Result<NotesStatistics>>.fromHandlers(
          handleData: _onFacts,
          handleError: _onError,
        ),
      );

  void _onFacts(List<NoteFactsModel> models, EventSink<Result<NotesStatistics>> sink) {
    sink.add(Result.success(NotesStatistics.of(models.map(_toEntity).toList(), now: _now())));
  }

  void _onError(Object error, StackTrace stackTrace, EventSink<Result<NotesStatistics>> sink) {
    _logger.e('$_watchFailureLog$error');
    sink.add(const Result.failure(_loadFailedMessage));
  }

  static NoteFacts _toEntity(NoteFactsModel model) => model.toEntity();
}
