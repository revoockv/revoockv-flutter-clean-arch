import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/note.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';
import 'notes_event.dart';
import 'notes_state.dart';

/// The notes list: follows [WatchNotesUseCase] and turns every result into a [NotesState].
final class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final WatchNotesUseCase _watchNotesUseCase;

  /// Creates the bloc; it starts with [NotesLoading] and follows the notes after [NotesSubscribed].
  NotesBloc({required this._watchNotesUseCase}) : super(const NotesLoading()) {
    on<NotesSubscribed>(_onSubscribed);
  }

  Future<void> _onSubscribed(NotesSubscribed event, Emitter<NotesState> emit) =>
      emit.forEach<Result<List<Note>>>(_watchNotesUseCase(), onData: _toState);

  static NotesState _toState(Result<List<Note>> result) => switch (result) {
        SuccessResult<List<Note>>(:final List<Note> value) => NotesLoaded(value),
        FailureResult<List<Note>>(:final String error) => NotesLoadFailed(error),
      };
}
