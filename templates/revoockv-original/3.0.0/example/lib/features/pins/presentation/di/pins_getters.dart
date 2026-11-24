import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/toggle_pin_use_case.dart';
import '../../domain/use_cases/watch_pinned_notes_use_case.dart';

/// Watch use case for the live pins.
WatchPinnedNotesUseCase get watchPinnedNotesUseCase => di<WatchPinnedNotesUseCase>();

/// Action use case that pins or unpins a note.
TogglePinUseCase get togglePinUseCase => di<TogglePinUseCase>();
