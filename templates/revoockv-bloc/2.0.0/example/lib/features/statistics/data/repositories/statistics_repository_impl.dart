import 'dart:async';

import 'package:example_app/core/domain/entities/result.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';
import 'package:example_app/features/pins/domain/entities/pinned_notes.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/note_facts.dart';
import '../../domain/entities/notes_statistics.dart';
import '../../domain/entities/statistics_failure.dart';
import '../../domain/repositories/statistics_repository.dart';

/// Statistics repository: counts the notes of the notes feature and the pins of the pins feature whenever either
/// changes (once both have arrived).
///
/// It has no data source of its own: it uses the two features through their domain (repository interfaces), never
/// their tables, so a change of their storage cannot break it.
final class StatisticsRepositoryImpl implements StatisticsRepository {
  static const String _loadFailureLog = 'WatchNotesStatistics: failure — the notes or the pins could not be loaded';

  final NotesRepository _notes;

  final PinsRepository _pins;

  final Logger _logger;

  final DateTime Function() _now;

  /// Creates the repository over the notes and the pins; `now` is the clock that says which day is today.
  StatisticsRepositoryImpl({
    required this._notes,
    required this._pins,
    required this._logger,
    this._now = DateTime.now,
  });

  @override
  Stream<Result<NotesStatistics, StatisticsFailure>> watchNotesStatistics() {
    Result<List<Note>, NoteFailure>? notes;
    Result<PinnedNotes, PinFailure>? pins;
    StreamSubscription<Result<List<Note>, NoteFailure>>? notesSubscription;
    StreamSubscription<Result<PinnedNotes, PinFailure>>? pinsSubscription;
    late final StreamController<Result<NotesStatistics, StatisticsFailure>> controller;

    void count() {
      final Result<List<Note>, NoteFailure>? lastNotes = notes;
      final Result<PinnedNotes, PinFailure>? lastPins = pins;
      if (lastNotes == null || lastPins == null) return;
      controller.add(_countOf(lastNotes, lastPins));
    }

    void onNotes(Result<List<Note>, NoteFailure> result) {
      notes = result;
      count();
    }

    void onPins(Result<PinnedNotes, PinFailure> result) {
      pins = result;
      count();
    }

    void start() {
      notesSubscription = _notes.watchNotes().listen(onNotes);
      pinsSubscription = _pins.watchPinnedNotes().listen(onPins);
    }

    Future<void> stop() async {
      await notesSubscription?.cancel();
      await pinsSubscription?.cancel();
    }

    controller = StreamController<Result<NotesStatistics, StatisticsFailure>>(onListen: start, onCancel: stop);
    return controller.stream;
  }

  Result<NotesStatistics, StatisticsFailure> _countOf(
    Result<List<Note>, NoteFailure> notes,
    Result<PinnedNotes, PinFailure> pins,
  ) => switch ((notes, pins)) {
    (
      SuccessResult<List<Note>, NoteFailure>(value: final List<Note> stored),
      SuccessResult<PinnedNotes, PinFailure>(value: final PinnedNotes pinned),
    ) =>
      Result.success(
        NotesStatistics.of(<NoteFacts>[for (final Note note in stored) _factsOf(note, pinned)], now: _now()),
      ),
    _ => _failed(),
  };

  Result<NotesStatistics, StatisticsFailure> _failed() {
    _logger.e(_loadFailureLog);
    return const Result.failure(StatisticsFailure.load);
  }

  static NoteFacts _factsOf(Note note, PinnedNotes pins) => NoteFacts(
    text: note.text,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    isPinned: pins.contains(note.id),
  );
}
