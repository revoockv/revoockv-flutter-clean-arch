import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/pin_failure.dart';
import '../entities/pinned_notes.dart';
import '../repositories/pins_repository.dart';

/// Watch use case: the pinned notes, live.
final class WatchPinnedNotesUseCase {
  final PinsRepository _repository;

  /// Creates the use case.
  WatchPinnedNotesUseCase(this._repository);

  /// The pins; the same listenable on every call.
  ValueListenable<ResultState<PinnedNotes, PinFailure>> call() => _repository.watchPinnedNotes();
}
