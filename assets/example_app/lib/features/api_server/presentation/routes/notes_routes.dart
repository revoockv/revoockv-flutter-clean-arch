import 'dart:async';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/core/presentation/routes/json_requests.dart';
import 'package:example_app/core/presentation/routes/json_responses.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:relic/relic.dart' show RelicRouter, Request, Response, RouteEx, RouterInjectable;

import '../dto/add_note_request_dto.dart';
import '../dto/note_dto.dart';

/// HTTP routes over the use cases of the notes feature.
///
/// Handlers only translate: request → use case → response. The use cases come in as functions, like in a controller.
final class NotesRoutes implements RouterInjectable {
  static const String _notesPath = '/notes';
  static const String _notesKey = 'notes';
  static const String _loadingMessage = 'The notes are still loading';
  static const String _invalidBodyMessage = 'The body must be {"text": "<note text>"}';

  final ValueListenable<ResultState<List<Note>>> Function() _watchNotes;

  final Future<Result<void>> Function(String text) _addNote;

  /// Creates the routes with the use cases they call: `watchNotesUseCase.call`, `addNoteUseCase.call`.
  const NotesRoutes({required this._watchNotes, required this._addNote});

  @override
  void injectIn(RelicRouter router) {
    router
      ..get(_notesPath, _onGetNotes)
      ..post(_notesPath, _onAddNote);
  }

  /// `GET /notes` → `200 {"notes": [...]}`, `503` while loading, `400` with the load error.
  Response _onGetNotes(Request request) => _watchNotes().value.when(
    idle: _loadingResponse,
    loading: _loadingResponse,
    success: _notesResponse,
    failure: JsonResponses.failure,
  );

  /// `POST /notes {"text": "..."}` → `204`, `400` with the message of the use case.
  Future<Response> _onAddNote(Request request) async {
    final Result<Map<String, Object?>> body = await JsonRequests.readObject(request);
    return body.when<FutureOr<Response>>(success: _addNoteFromJson, failure: JsonResponses.failure);
  }

  Future<Response> _addNoteFromJson(Map<String, Object?> json) async {
    final AddNoteRequestDto? dto = AddNoteRequestDto.fromJson(json);
    if (dto == null) return JsonResponses.failure(_invalidBodyMessage);
    final Result<void> result = await _addNote(dto.text);
    return result.when(success: _noContentResponse, failure: JsonResponses.failure);
  }

  Response _loadingResponse() => JsonResponses.unavailable(_loadingMessage);

  Response _notesResponse(List<Note> notes) =>
      JsonResponses.ok(<String, Object?>{_notesKey: notes.map(_noteJson).toList()});

  Response _noContentResponse(void _) => JsonResponses.noContent();

  Map<String, Object?> _noteJson(Note note) => NoteDto.fromEntity(note).toJson();
}
