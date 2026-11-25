import 'package:example_app/core/domain/entities/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pin_failure.dart';
import '../../domain/use_cases/toggle_pin_use_case.dart';
import 'pin_actions_state.dart';

/// Pins and unpins notes; its state is the progress of the last one. One at a time.
final class PinActionsCubit extends Cubit<PinActionsState> {
  final TogglePinUseCase _togglePinUseCase;

  /// Creates the cubit.
  PinActionsCubit({required this._togglePinUseCase}) : super(const PinActionsIdle());

  /// Pins or unpins the note [noteId]; ignored while another one runs.
  Future<void> toggle(String noteId) async {
    if (state.isRunning) return;
    emit(const PinActionsRunning());
    final Result<void, PinFailure> result = await _togglePinUseCase(noteId);
    if (isClosed) return;
    emit(switch (result) {
      SuccessResult<void, PinFailure>() => const PinActionsIdle(),
      FailureResult<void, PinFailure>(:final PinFailure failure) => PinActionsFailed(failure),
    });
  }
}
