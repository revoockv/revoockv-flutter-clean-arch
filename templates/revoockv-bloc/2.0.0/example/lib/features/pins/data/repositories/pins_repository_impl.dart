import 'dart:async';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/pin_failure.dart';
import '../../domain/entities/pinned_notes.dart';
import '../../domain/repositories/pins_repository.dart';
import '../data_sources/pins_data_source.dart';
import '../models/pin_model.dart';

/// Pins repository: maps the data source's models to [PinnedNotes] and its exceptions to [PinFailure]s.
final class PinsRepositoryImpl implements PinsRepository {
  static const String _toggleSuccessLog = 'TogglePin: success — note ';
  static const String _toggleFailureLog = 'TogglePin: failure — ';
  static const String _unpinFailureLog = 'Unpin: failure — ';
  static const String _watchFailureLog = 'WatchPins: failure — ';

  final PinsDataSource _dataSource;

  final Logger _logger;

  /// Creates the repository.
  PinsRepositoryImpl({required this._dataSource, required this._logger});

  @override
  Stream<Result<PinnedNotes, PinFailure>> watchPinnedNotes() => _dataSource.watchPins().transform(
    StreamTransformer<List<PinModel>, Result<PinnedNotes, PinFailure>>.fromHandlers(
      handleData: _onPins,
      handleError: _onError,
    ),
  );

  @override
  Future<Result<void, PinFailure>> togglePin(String noteId) async {
    try {
      if (await _isPinned(noteId)) {
        await _dataSource.remove(noteId);
      } else {
        await _dataSource.add(PinModel(noteId: noteId));
      }
      _logger.i('$_toggleSuccessLog$noteId');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_toggleFailureLog$e');
      return const Result.failure(PinFailure.toggle);
    }
  }

  @override
  Future<Result<void, PinFailure>> unpin(String noteId) async {
    try {
      if (await _isPinned(noteId)) await _dataSource.remove(noteId);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_unpinFailureLog$e');
      return const Result.failure(PinFailure.toggle);
    }
  }

  Future<bool> _isPinned(String noteId) async =>
      (await _dataSource.watchPins().first).any((PinModel pin) => pin.noteId == noteId);

  void _onPins(List<PinModel> models, EventSink<Result<PinnedNotes, PinFailure>> sink) {
    sink.add(Result.success(PinnedNotes(models.map(_noteIdOf).toSet())));
  }

  void _onError(Object error, StackTrace stackTrace, EventSink<Result<PinnedNotes, PinFailure>> sink) {
    _logger.e('$_watchFailureLog$error');
    sink.add(const Result.failure(PinFailure.load));
  }

  static String _noteIdOf(PinModel model) => model.noteId;
}
