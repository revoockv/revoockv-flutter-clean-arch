import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/add_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/watch_notes_use_case.dart';

/// Watch use case for the live list of notes.
WatchNotesUseCase get watchNotesUseCase => di<WatchNotesUseCase>();

/// Action use case that adds a note.
AddNoteUseCase get addNoteUseCase => di<AddNoteUseCase>();

/// Action use case that deletes a note.
DeleteNoteUseCase get deleteNoteUseCase => di<DeleteNoteUseCase>();
