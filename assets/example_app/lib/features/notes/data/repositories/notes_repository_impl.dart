import 'dart:async';

import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../data_sources/notes_data_source.dart';
import '../models/note_model.dart';

/// Notes repository: mirrors the data source into a private [ValueNotifier] of [ResultState].
final class NotesRepositoryImpl implements NotesRepository, DisposableResource {
  /// Message shown when a note cannot be added.
  static const String _addFailedMessage = 'Could not add the note';

  /// Message shown when a note cannot be deleted.
  static const String _deleteFailedMessage = 'Could not delete the note';

  /// Message shown when the notes cannot be loaded.
  static const String _loadFailedMessage = 'Could not load the notes';

  static const String _initLog = 'NotesRepository init: subscribed to notes';
  static const String _disposeLog = 'NotesRepository dispose: unsubscribed';
  static const String _addSuccessLog = 'AddNote: success — note ';
  static const String _addedLog = ' added';
  static const String _addFailureLog = 'AddNote: failure — ';
  static const String _deleteSuccessLog = 'DeleteNote: success — note ';
  static const String _deletedLog = ' deleted';
  static const String _deleteFailureLog = 'DeleteNote: failure — ';
  static const String _watchFailureLog = 'WatchNotes: failure — ';

  final NotesDataSource _dataSource;

  final Logger _logger;

  final ValueNotifier<ResultState<List<Note>>> _notes = ValueNotifier<ResultState<List<Note>>>(ResultState.loading);

  StreamSubscription<List<NoteModel>>? _sub;

  /// Creates the repository.
  NotesRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to the data source; returns this for `registerSingletonAsync`.
  Future<NotesRepositoryImpl> init() async {
    _sub ??= _dataSource.watchNotes().listen(_onNotes, onError: _onError);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state. Called by DI only.
  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _notes.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ResultState<List<Note>>> watchNotes() => _notes;

  @override
  Future<Result<void>> addNote(String text) async {
    try {
      final NoteModel model = await _dataSource.add(text);
      _logger.i('$_addSuccessLog${model.id}$_addedLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_addFailureLog$e');
      return const Result.failure(_addFailedMessage);
    }
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    try {
      await _dataSource.delete(id);
      _logger.i('$_deleteSuccessLog$id$_deletedLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_deleteFailureLog$e');
      return const Result.failure(_deleteFailedMessage);
    }
  }

  void _onNotes(List<NoteModel> models) {
    _notes.value = ResultState.success(models.map(_toEntity).toList());
  }

  void _onError(Object error) {
    _logger.e('$_watchFailureLog$error');
    _notes.value = const ResultState.failure(_loadFailedMessage);
  }

  Note _toEntity(NoteModel model) => model.toEntity();
}
