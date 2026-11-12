import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';
import '../blocs/note_actions_cubit.dart';
import '../blocs/note_actions_state.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/notes_event.dart';
import '../widgets/add_note_widget.dart';
import '../widgets/notes_list_widget.dart';

/// Notes screen: creates its blocs from the feature's use cases and shows action errors as snackbars.
final class NotesPage extends StatelessWidget {
  /// Creates the page.
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: const [
        BlocProvider<NotesBloc>(create: _createNotesBloc),
        BlocProvider<NoteActionsCubit>(create: _createNoteActionsCubit),
      ],
      child: const _NotesViewWidget(),
    );
  }

  static NotesBloc _createNotesBloc(BuildContext context) =>
      NotesBloc(watchNotesUseCase: context.read<WatchNotesUseCase>())..add(const NotesSubscribed());

  static NoteActionsCubit _createNoteActionsCubit(BuildContext context) => NoteActionsCubit(
        addNoteUseCase: context.read<AddNoteUseCase>(),
        deleteNoteUseCase: context.read<DeleteNoteUseCase>(),
      );
}

/// The screen below the blocs; only its listener reacts to failures, nothing here rebuilds.
final class _NotesViewWidget extends StatelessWidget {
  /// Title of the app bar.
  static const String _title = 'Notes';

  const _NotesViewWidget();

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteActionsCubit, NoteActionsState>(
      listenWhen: _isFailure,
      listener: _onActionFailed,
      child: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            children: <Widget>[
              AddNoteWidget(),
              SizedBox(height: AppTheme.spacingMedium),
              Expanded(child: NotesListWidget()),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isFailure(NoteActionsState previous, NoteActionsState current) => current is NoteActionsFailed;

  void _onActionFailed(BuildContext context, NoteActionsState state) {
    if (state is! NoteActionsFailed) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
  }
}
