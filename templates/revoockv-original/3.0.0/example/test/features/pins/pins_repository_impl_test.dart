import 'package:example_app/core/data/data_sources/in_memory_app_database.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/pins/data/data_sources/database_pins_data_source.dart';
import 'package:example_app/features/pins/data/repositories/pins_repository_impl.dart';
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';
import 'package:example_app/features/pins/domain/entities/pinned_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

PinnedNotes pinsOf(PinsRepositoryImpl repository) =>
    (repository.watchPinnedNotes().value as SuccessResultState<PinnedNotes, PinFailure>).value;

void main() {
  late PinsRepositoryImpl repository;

  setUp(() async {
    final DatabasePinsDataSource pins = DatabasePinsDataSource(database: InMemoryAppDatabase(latency: Duration.zero));
    repository = await PinsRepositoryImpl(dataSource: pins, logger: Logger(level: Level.off)).init();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => repository.dispose());

  test('toggling pins a note and pins it no more', () async {
    expect((await repository.togglePin('n1')).isSuccess, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(pinsOf(repository).contains('n1'), isTrue);

    await repository.togglePin('n1');
    await Future<void>.delayed(Duration.zero);
    expect(pinsOf(repository), PinnedNotes.none);
  });

  test('unpinning a note that is not pinned succeeds and changes nothing', () async {
    expect((await repository.unpin('n1')).isSuccess, isTrue);
    expect(pinsOf(repository), PinnedNotes.none);
  });
}
