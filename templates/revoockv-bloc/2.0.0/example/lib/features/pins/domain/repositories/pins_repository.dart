import 'package:example_app/core/domain/entities/result.dart';

import '../entities/pin_failure.dart';
import '../entities/pinned_notes.dart';

/// The pinned notes.
abstract interface class PinsRepository {
  /// The pins now and after every change.
  Stream<Result<PinnedNotes, PinFailure>> watchPinnedNotes();

  /// Pins the note [noteId], or unpins it when it is pinned.
  Future<Result<void, PinFailure>> togglePin(String noteId);

  /// Unpins the note [noteId]; nothing happens when it is not pinned.
  Future<Result<void, PinFailure>> unpin(String noteId);
}
