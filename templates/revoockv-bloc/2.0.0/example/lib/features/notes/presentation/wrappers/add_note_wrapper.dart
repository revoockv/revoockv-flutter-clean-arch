import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/note_actions_cubit.dart';
import '../blocs/note_actions_state.dart';
import '../widgets/add_note_widget.dart';

/// Gives [AddNoteWidget] whether an action runs: rebuilds only when it starts or ends. Owns the field's controller
/// and clears it after the note was added, so a failed note keeps its text.
final class AddNoteWrapper extends StatefulWidget {
  /// Hint of the empty field.
  final String hintText;

  /// Label of the add button.
  final String addLabel;

  /// Called with the written text when the add button is pressed; the page adds the note.
  final ValueChanged<String> onAddPressed;

  /// Creates the wrapper.
  const AddNoteWrapper({required this.hintText, required this.addLabel, required this.onAddPressed, super.key});

  @override
  State<AddNoteWrapper> createState() => _AddNoteWrapperState();
}

final class _AddNoteWrapperState extends State<AddNoteWrapper> {
  late final TextEditingController _noteTextController;

  @override
  void initState() {
    super.initState();
    _noteTextController = TextEditingController();
  }

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteActionsCubit, NoteActionsState>(
      listenWhen: _isAdded,
      listener: _onAdded,
      child: BlocSelector<NoteActionsCubit, NoteActionsState, bool>(
        selector: _isRunning,
        builder: (BuildContext context, bool isAdding) => AddNoteWidget(
          noteTextController: _noteTextController,
          isAdding: isAdding,
          hintText: widget.hintText,
          addLabel: widget.addLabel,
          onAddPressed: _onAddPressed,
        ),
      ),
    );
  }

  static bool _isAdded(NoteActionsState previous, NoteActionsState current) =>
      current == const NoteActionsDone(NoteAction.added);

  static bool _isRunning(NoteActionsState state) => state.isRunning;

  void _onAdded(BuildContext context, NoteActionsState state) {
    _noteTextController.clear();
  }

  void _onAddPressed() {
    widget.onAddPressed(_noteTextController.text);
  }
}
