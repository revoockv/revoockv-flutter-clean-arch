import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/update_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';
import '../blocs/note_actions_cubit.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_event.dart';
import 'package:example_app/features/pins/domain/use_cases/toggle_pin_use_case.dart';
import 'package:example_app/features/pins/domain/use_cases/watch_pinned_notes_use_case.dart';
import 'package:example_app/features/pins/presentation/blocs/pin_actions_cubit.dart';
import 'package:example_app/features/pins/presentation/blocs/pins_bloc.dart';
import 'package:example_app/features/pins/presentation/blocs/pins_event.dart';
import 'notes_view.dart';

/// Notes tab: creates its blocs from the feature's use cases for [NotesView].
final class NotesPage extends StatelessWidget {
  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: const [
        BlocProvider<NotesBloc>(create: _createNotesBloc),
        BlocProvider<NoteActionsCubit>(create: _createNoteActionsCubit),
        BlocProvider<PinsBloc>(create: _createPinsBloc),
        BlocProvider<PinActionsCubit>(create: _createPinActionsCubit),
      ],
      child: const NotesView(),
    );
  }

  static NotesBloc _createNotesBloc(BuildContext context) =>
      NotesBloc(watchNotesUseCase: context.read<WatchNotesUseCase>())..add(const NotesSubscribed());

  static NoteActionsCubit _createNoteActionsCubit(BuildContext context) => NoteActionsCubit(
    addNoteUseCase: context.read<AddNoteUseCase>(),
    updateNoteUseCase: context.read<UpdateNoteUseCase>(),
    deleteNoteUseCase: context.read<DeleteNoteUseCase>(),
  );

  static PinsBloc _createPinsBloc(BuildContext context) =>
      PinsBloc(watchPinnedNotesUseCase: context.read<WatchPinnedNotesUseCase>())..add(const PinsSubscribed());

  static PinActionsCubit _createPinActionsCubit(BuildContext context) =>
      PinActionsCubit(togglePinUseCase: context.read<TogglePinUseCase>());
}
