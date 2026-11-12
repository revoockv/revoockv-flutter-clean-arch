import 'dart:async';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../data_sources/notes_data_source.dart';
import '../models/note_model.dart';

/// Notes repository: maps the data source's models to entities and its exceptions to failures.
final class NotesRepositoryImpl implements NotesRepository {
  /// Message shown when a note cannot be added.
  static const String _addFailedMessage = 'Could not add the note';

  /// Message shown when a note cannot be deleted.
  static const String _deleteFailedMessage = 'Could not delete the note';

  /// Message shown when the notes cannot be loaded.
  static const String _loadFailedMessage = 'Could not load the notes';

  static const String _addSuccessLog = 'AddNote: success — note ';
  static const String _addedLog = ' added';
  static const String _addFailureLog = 'AddNote: failure — ';
  static const String _deleteSuccessLog = 'DeleteNote: success — note ';
  static const String _deletedLog = ' deleted';
  static const String _deleteFailureLog = 'DeleteNote: failure — ';
  static const String _watchFailureLog = 'WatchNotes: failure — ';

  final NotesDataSource _dataSource;

  final Logger _logger;

  /// Creates the repository.
  NotesRepositoryImpl({required this._dataSource, required this._logger});

  @override
  Stream<Result<List<Note>>> watchNotes() => _dataSource.watchNotes().transform(
        StreamTransformer<List<NoteModel>, Result<List<Note>>>.fromHandlers(
          handleData: _onNotes,
          handleError: _onError,
        ),
      );

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

  void _onNotes(List<NoteModel> models, EventSink<Result<List<Note>>> sink) {
    sink.add(Result.success(models.map(_toEntity).toList()));
  }

  void _onError(Object error, StackTrace stackTrace, EventSink<Result<List<Note>>> sink) {
    _logger.e('$_watchFailureLog$error');
    sink.add(const Result.failure(_loadFailedMessage));
  }

  Note _toEntity(NoteModel model) => model.toEntity();
}
