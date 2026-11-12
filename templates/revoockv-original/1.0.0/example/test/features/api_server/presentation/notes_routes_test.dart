import 'dart:convert';
import 'dart:io';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/api_server/data/data_sources/relic_api_server_data_source.dart';
import 'package:example_app/features/api_server/presentation/middleware/api_token_middleware.dart';
import 'package:example_app/features/api_server/presentation/routes/notes_routes.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Status and JSON body of one HTTP response.
typedef _Reply = ({int status, Object? json});

void main() {
  const String token = 'secret-token';
  late ValueNotifier<ResultState<List<Note>>> notes;
  late List<String> added;
  late RelicApiServerDataSource server;
  late HttpClient client;
  late int port;

  Future<Result<void>> addNote(String text) async {
    if (text.trim().isEmpty) return const Result.failure('Note text must not be empty');
    added.add(text);
    return Result.ok;
  }

  Future<_Reply> send(String method, {String? bearer, String? body}) async {
    final HttpClientRequest request = await client.openUrl(method, Uri.parse('http://localhost:$port/notes'));
    if (bearer != null) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    if (body != null) request.write(body);
    final HttpClientResponse response = await request.close();
    final String text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, json: text.isEmpty ? null : jsonDecode(text));
  }

  setUp(() async {
    notes = ValueNotifier<ResultState<List<Note>>>(
      const ResultState<List<Note>>.success(<Note>[Note(id: '1', text: 'Buy milk')]),
    );
    added = <String>[];
    client = HttpClient();
    server = RelicApiServerDataSource(
      routes: <NotesRoutes>[NotesRoutes(watchNotes: () => notes, addNote: addNote)],
      middleware: [apiTokenMiddleware((String t) => t == token)],
      address: InternetAddress.loopbackIPv4,
    );
    port = await server.start(port: 0);
  });

  tearDown(() async {
    client.close(force: true);
    await server.dispose();
    notes.dispose();
  });

  test('without the token or with a wrong one every request is 401', () async {
    expect((await send('GET')).status, 401);
    expect((await send('GET', bearer: 'wrong')).status, 401);
    expect((await send('POST', bearer: 'wrong', body: '{"text": "x"}')).status, 401);
    expect(added, isEmpty);
  });

  test('GET /notes answers the current notes', () async {
    final _Reply reply = await send('GET', bearer: token);

    expect(reply.status, 200);
    expect(reply.json, <String, Object?>{
      'notes': <Object?>[
        <String, Object?>{'id': '1', 'text': 'Buy milk'},
      ],
    });
  });

  test('GET /notes is 503 while the notes load', () async {
    notes.value = ResultState.loading;

    expect((await send('GET', bearer: token)).status, 503);
  });

  test('POST /notes calls the use case; its failure is 400 with the message', () async {
    expect((await send('POST', bearer: token, body: '{"text": "Call mom"}')).status, 204);
    expect(added, <String>['Call mom']);

    final _Reply blank = await send('POST', bearer: token, body: '{"text": " "}');
    expect(blank.status, 400);
    expect(blank.json, <String, Object?>{'error': 'Note text must not be empty'});

    expect((await send('POST', bearer: token, body: '{oops')).status, 400);
    expect((await send('POST', bearer: token, body: '{"text": 1}')).status, 400);
  });
}
