import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/api_server/data/repositories/api_server_repository_impl.dart';
import 'package:example_app/features/api_server/domain/entities/api_server_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../fake_api_server_data_sources.dart';

void main() {
  final Logger silent = Logger(level: Level.off);

  test('start listens, makes a token and accepts only it', () async {
    final FakeApiServerDataSource dataSource = FakeApiServerDataSource();
    final ApiServerRepositoryImpl repository = ApiServerRepositoryImpl(dataSource: dataSource, logger: silent);

    expect(await repository.start(), Result.ok);

    final ApiServerState state = repository.watchState().value;
    expect(state, isA<RunningApiServerState>());
    final String token = (state as RunningApiServerState).token;
    expect(state.port, 8080);
    expect(token.length, greaterThanOrEqualTo(43));
    expect(repository.isTokenValid(token), isTrue);
    expect(repository.isTokenValid('${token}x'), isFalse);
    expect(repository.isTokenValid(''), isFalse);
    await repository.dispose();
  });

  test('stop turns the server off and the token stops working', () async {
    final FakeApiServerDataSource dataSource = FakeApiServerDataSource();
    final ApiServerRepositoryImpl repository = ApiServerRepositoryImpl(dataSource: dataSource, logger: silent);
    await repository.start();
    final String token = (repository.watchState().value as RunningApiServerState).token;

    await repository.stop();

    expect(repository.watchState().value, isA<StoppedApiServerState>());
    expect(dataSource.listening, isFalse);
    expect(repository.isTokenValid(token), isFalse);
    await repository.dispose();
  });

  test('every start makes a new token', () async {
    final ApiServerRepositoryImpl repository =
        ApiServerRepositoryImpl(dataSource: FakeApiServerDataSource(), logger: silent);
    await repository.start();
    final String first = (repository.watchState().value as RunningApiServerState).token;
    await repository.stop();
    await repository.start();

    expect((repository.watchState().value as RunningApiServerState).token, isNot(first));
    await repository.dispose();
  });

  test('a taken port becomes a human-readable failure', () async {
    final ApiServerRepositoryImpl repository =
        ApiServerRepositoryImpl(dataSource: BusyPortApiServerDataSource(), logger: silent);

    final Result<void> result = await repository.start();

    expect(result.isFailure, isTrue);
    expect(repository.watchState().value, isA<FailedApiServerState>());
    await repository.dispose();
  });
}
