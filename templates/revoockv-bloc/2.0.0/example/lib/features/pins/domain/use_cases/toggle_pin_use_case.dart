import 'package:example_app/core/domain/entities/result.dart';

import '../entities/pin_failure.dart';
import '../repositories/pins_repository.dart';

/// Action use case: pins a note, or unpins it when it is pinned.
final class TogglePinUseCase {
  final PinsRepository _repository;

  /// Creates the use case.
  TogglePinUseCase(this._repository);

  /// Pins or unpins the note [noteId].
  Future<Result<void, PinFailure>> call(String noteId) => _repository.togglePin(noteId);
}
