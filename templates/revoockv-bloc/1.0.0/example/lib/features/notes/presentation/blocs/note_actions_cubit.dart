import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import 'note_actions_state.dart';

/// Adds and deletes notes; its state is the progress of the last action. One action at a time.
final class NoteActionsCubit extends Cubit<NoteActionsState> {
  final AddNoteUseCase _addNoteUseCase;

  final DeleteNoteUseCase _deleteNoteUseCase;

  /// Creates the cubit.
  NoteActionsCubit({required this._addNoteUseCase, required this._deleteNoteUseCase})
      : super(const NoteActionsIdle());

  /// Adds a note with [text]; ignored while another action runs.
  Future<void> add(String text) => _run(NoteAction.added, () => _addNoteUseCase(text));

  /// Deletes the note with [id]; ignored while another action runs.
  Future<void> delete(String id) => _run(NoteAction.deleted, () => _deleteNoteUseCase(id));

  Future<void> _run(NoteAction action, Future<Result<void>> Function() useCase) async {
    if (state.isRunning) return;
    emit(const NoteActionsRunning());
    final Result<void> result = await useCase();
    if (isClosed) return;
    emit(switch (result) {
      SuccessResult<void>() => NoteActionsDone(action),
      FailureResult<void>(:final String error) => NoteActionsFailed(error),
    });
  }
}
