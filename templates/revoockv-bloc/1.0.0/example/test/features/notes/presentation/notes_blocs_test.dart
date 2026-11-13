import 'package:bloc_test/bloc_test.dart';
import 'package:example_app/features/notes/data/data_sources/notes_data_source.dart';
import 'package:example_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:example_app/features/notes/domain/entities/note.dart';
import 'package:example_app/features/notes/domain/use_cases/add_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/delete_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/update_note_use_case.dart';
import 'package:example_app/features/notes/domain/use_cases/watch_notes_use_case.dart';
import 'package:example_app/features/notes/presentation/blocs/note_actions_cubit.dart';
import 'package:example_app/features/notes/presentation/blocs/note_actions_state.dart';
import 'package:example_app/features/notes/presentation/blocs/notes_bloc.dart';
import 'package:example_app/features/notes/presentation/blocs/notes_event.dart';
import 'package:example_app/features/notes/presentation/blocs/notes_state.dart';
import 'package:logger/logger.dart';

import '../fake_notes_data_sources.dart';

NotesRepositoryImpl repositoryOf(NotesDataSource dataSource) =>
    NotesRepositoryImpl(dataSource: dataSource, logger: Logger(level: Level.off));

NoteActionsCubit actionsOn(NotesDataSource dataSource) {
  final NotesRepositoryImpl repository = repositoryOf(dataSource);
  return NoteActionsCubit(
    addNoteUseCase: AddNoteUseCase(repository),
    updateNoteUseCase: UpdateNoteUseCase(repository),
    deleteNoteUseCase: DeleteNoteUseCase(repository),
  );
}

void main() {
  blocTest<NotesBloc, NotesState>(
    'follows the notes after NotesSubscribed',
    build: () => NotesBloc(watchNotesUseCase: WatchNotesUseCase(repositoryOf(memoryNotes()))),
    act: (NotesBloc bloc) => bloc.add(const NotesSubscribed()),
    expect: () => const <NotesState>[NotesLoaded(<Note>[])],
  );

  blocTest<NotesBloc, NotesState>(
    'a load error becomes NotesLoadFailed',
    build: () => NotesBloc(watchNotesUseCase: WatchNotesUseCase(repositoryOf(BrokenStreamNotesDataSource()))),
    act: (NotesBloc bloc) => bloc.add(const NotesSubscribed()),
    expect: () => const <NotesState>[NotesLoadFailed('Could not load the notes')],
  );

  blocTest<NoteActionsCubit, NoteActionsState>(
    'add runs, then is done',
    build: () => actionsOn(memoryNotes()),
    act: (NoteActionsCubit cubit) => cubit.add('Buy milk'),
    expect: () => const <NoteActionsState>[NoteActionsRunning(), NoteActionsDone(NoteAction.added)],
  );

  blocTest<NoteActionsCubit, NoteActionsState>(
    'changing a missing note ends with its message',
    build: () => actionsOn(memoryNotes()),
    act: (NoteActionsCubit cubit) => cubit.update('missing', 'Text'),
    expect: () => const <NoteActionsState>[NoteActionsRunning(), NoteActionsFailed('Could not change the note')],
  );

  blocTest<NoteActionsCubit, NoteActionsState>(
    'a failed add ends with its message',
    build: () => actionsOn(FailingNotesDataSource()),
    act: (NoteActionsCubit cubit) => cubit.add('Buy milk'),
    expect: () => const <NoteActionsState>[NoteActionsRunning(), NoteActionsFailed('Could not add the note')],
  );

  blocTest<NoteActionsCubit, NoteActionsState>(
    'a second action while one runs is ignored',
    build: () => actionsOn(memoryNotes()),
    act: (NoteActionsCubit cubit) {
      cubit.add('One');
      cubit.add('Two');
    },
    expect: () => const <NoteActionsState>[NoteActionsRunning(), NoteActionsDone(NoteAction.added)],
  );
}
