import 'dart:async';

import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/pin_failure.dart';
import '../../domain/entities/pinned_notes.dart';
import '../../domain/repositories/pins_repository.dart';
import '../data_sources/pins_data_source.dart';
import '../models/pin_model.dart';

/// Pins repository: mirrors the data source into a private [ValueNotifier] of [ResultState].
final class PinsRepositoryImpl implements PinsRepository, DisposableResource {
  static const String _initLog = 'PinsRepository init: subscribed to pins';
  static const String _disposeLog = 'PinsRepository dispose: unsubscribed';
  static const String _toggleSuccessLog = 'TogglePin: success — note ';
  static const String _toggleFailureLog = 'TogglePin: failure — ';
  static const String _unpinFailureLog = 'Unpin: failure — ';
  static const String _watchFailureLog = 'WatchPins: failure — ';

  final PinsDataSource _dataSource;

  final Logger _logger;

  final ValueNotifier<ResultState<PinnedNotes, PinFailure>> _pins =
      ValueNotifier<ResultState<PinnedNotes, PinFailure>>(ResultState.loading);

  StreamSubscription<List<PinModel>>? _sub;

  /// Creates the repository.
  PinsRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to the data source; returns this for `registerSingletonAsync`.
  Future<PinsRepositoryImpl> init() async {
    _sub ??= _dataSource.watchPins().listen(_onPins, onError: _onError);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _pins.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ResultState<PinnedNotes, PinFailure>> watchPinnedNotes() => _pins;

  @override
  Future<Result<void, PinFailure>> togglePin(String noteId) async {
    try {
      if (_isPinned(noteId)) {
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
    if (!_isPinned(noteId)) return Result.ok;
    try {
      await _dataSource.remove(noteId);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_unpinFailureLog$e');
      return const Result.failure(PinFailure.toggle);
    }
  }

  bool _isPinned(String noteId) => switch (_pins.value) {
    SuccessResultState<PinnedNotes, PinFailure>(:final PinnedNotes value) => value.contains(noteId),
    _ => false,
  };

  void _onPins(List<PinModel> models) {
    _pins.value = ResultState.success(PinnedNotes(models.map(_noteIdOf).toSet()));
  }

  void _onError(Object error) {
    _logger.e('$_watchFailureLog$error');
    _pins.value = const ResultState.failure(PinFailure.load);
  }

  static String _noteIdOf(PinModel model) => model.noteId;
}
