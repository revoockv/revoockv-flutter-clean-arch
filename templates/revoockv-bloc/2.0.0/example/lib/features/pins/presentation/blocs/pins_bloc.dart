import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pin_failure.dart';
import '../../domain/entities/pinned_notes.dart';
import '../../domain/use_cases/watch_pinned_notes_use_case.dart';
import 'pins_event.dart';
import 'pins_state.dart';

/// The pins: follows [WatchPinnedNotesUseCase] and turns every result into a [PinsState].
final class PinsBloc extends Bloc<PinsEvent, PinsState> {
  final WatchPinnedNotesUseCase _watchPinnedNotesUseCase;

  /// Creates the bloc; it starts with [PinsLoading] and follows the pins after [PinsSubscribed].
  PinsBloc({required this._watchPinnedNotesUseCase}) : super(const PinsLoading()) {
    on<PinsSubscribed>(_onSubscribed);
  }

  Future<void> _onSubscribed(PinsSubscribed event, Emitter<PinsState> emit) =>
      emit.forEach<Result<PinnedNotes, PinFailure>>(_watchPinnedNotesUseCase(), onData: _toState);

  static PinsState _toState(Result<PinnedNotes, PinFailure> result) => switch (result) {
    SuccessResult<PinnedNotes, PinFailure>(:final PinnedNotes value) => PinsLoaded(value),
    FailureResult<PinnedNotes, PinFailure>(:final PinFailure failure) => PinsLoadFailed(failure),
  };
}
