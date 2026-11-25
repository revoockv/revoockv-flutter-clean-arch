import 'package:example_app/core/domain/entities/result.dart';

import '../entities/pin_failure.dart';
import '../entities/pinned_notes.dart';
import '../repositories/pins_repository.dart';

/// Watch use case: the pinned notes, live.
final class WatchPinnedNotesUseCase {
  final PinsRepository _repository;

  /// Creates the use case.
  WatchPinnedNotesUseCase(this._repository);

  /// The pins now and after every change.
  Stream<Result<PinnedNotes, PinFailure>> call() => _repository.watchPinnedNotes();
}
