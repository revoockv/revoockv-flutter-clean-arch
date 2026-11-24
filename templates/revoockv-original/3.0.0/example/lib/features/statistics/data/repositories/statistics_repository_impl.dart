import 'package:example_app/core/domain/entities/disposable_resource.dart';
import 'package:example_app/core/domain/entities/result_state.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/entities/note_failure.dart';
import 'package:example_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:example_app/features/pins/domain/entities/pin_failure.dart';
import 'package:example_app/features/pins/domain/entities/pinned_notes.dart';
import 'package:example_app/features/pins/domain/repositories/pins_repository.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/note_facts.dart';
import '../../domain/entities/notes_statistics.dart';
import '../../domain/entities/statistics_failure.dart';
import '../../domain/repositories/statistics_repository.dart';

/// Statistics repository: counts the notes of the notes feature and the pins of the pins feature on every change of
/// either, into a private [ValueNotifier] of [ResultState].
///
/// It has no data source of its own: it uses the two features through their domain (repository interfaces), never
/// their tables, so a change of their storage cannot break it.
final class StatisticsRepositoryImpl implements StatisticsRepository, DisposableResource {
  static const String _initLog = 'StatisticsRepository init: listens to notes and pins';
  static const String _disposeLog = 'StatisticsRepository dispose: stopped listening';
  static const String _loadFailureLog = 'WatchNotesStatistics: failure — the notes or the pins could not be loaded';

  final ValueListenable<ResultState<List<Note>, NoteFailure>> _notes;

  final ValueListenable<ResultState<PinnedNotes, PinFailure>> _pins;

  final Logger _logger;

  final DateTime Function() _now;

  final ValueNotifier<ResultState<NotesStatistics, StatisticsFailure>> _statistics =
      ValueNotifier<ResultState<NotesStatistics, StatisticsFailure>>(ResultState.loading);

  /// Creates the repository over the notes and the pins; `now` is the clock that says which day is today.
  StatisticsRepositoryImpl({
    required NotesRepository notes,
    required PinsRepository pins,
    required this._logger,
    this._now = DateTime.now,
  }) : _notes = notes.watchNotes(),
       _pins = pins.watchPinnedNotes();

  /// Starts listening and counts what is there; returns this for DI.
  StatisticsRepositoryImpl init() {
    _notes.addListener(_count);
    _pins.addListener(_count);
    _count();
    _logger.i(_initLog);
    return this;
  }

  /// Stops listening and releases the state. Called by DI only.
  @override
  void dispose() {
    _notes.removeListener(_count);
    _pins.removeListener(_count);
    _statistics.dispose();
    _logger.i(_disposeLog);
  }

  /// Always the same instance — watch_it subscribes to it once.
  @override
  ValueListenable<ResultState<NotesStatistics, StatisticsFailure>> watchNotesStatistics() => _statistics;

  void _count() {
    _statistics.value = switch ((_notes.value, _pins.value)) {
      (FailureResultState<List<Note>, NoteFailure>(), _) || (_, FailureResultState<PinnedNotes, PinFailure>()) =>
        _failed(),
      (
        SuccessResultState<List<Note>, NoteFailure>(value: final List<Note> notes),
        SuccessResultState<PinnedNotes, PinFailure>(value: final PinnedNotes pins),
      ) =>
        ResultState.success(NotesStatistics.of(<NoteFacts>[for (final Note note in notes) _factsOf(note, pins)], now: _now())),
      _ => ResultState.loading,
    };
  }

  ResultState<NotesStatistics, StatisticsFailure> _failed() {
    _logger.e(_loadFailureLog);
    return const ResultState.failure(StatisticsFailure.load);
  }

  static NoteFacts _factsOf(Note note, PinnedNotes pins) => NoteFacts(
    text: note.text,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    isPinned: pins.contains(note.id),
  );
}
