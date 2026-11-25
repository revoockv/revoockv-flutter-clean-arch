import 'package:example_app/core/presentation/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/note_actions_cubit.dart';
import '../blocs/note_actions_state.dart';

/// Text field with an "Add" button. Owns the field's controller; the cubit adds the note.
///
/// The field is cleared only after a note was added, so a failed note keeps its text.
final class AddNoteWidget extends StatefulWidget {
  /// Creates the widget.
  const AddNoteWidget({super.key});

  @override
  State<AddNoteWidget> createState() => _AddNoteWidgetState();
}

final class _AddNoteWidgetState extends State<AddNoteWidget> {
  /// Hint of the text field.
  static const String _hintText = 'New note';

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
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _noteTextController,
              decoration: const InputDecoration(hintText: _hintText),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          _AddButtonWidget(onPressed: _onAddPressed),
        ],
      ),
    );
  }

  static bool _isAdded(NoteActionsState previous, NoteActionsState current) =>
      current == const NoteActionsDone(NoteAction.added);

  void _onAdded(BuildContext context, NoteActionsState state) {
    _noteTextController.clear();
  }

  void _onAddPressed() {
    context.read<NoteActionsCubit>().add(_noteTextController.text);
  }
}

/// The "Add" button — the only part that rebuilds, and only when an action starts or ends.
final class _AddButtonWidget extends StatelessWidget {
  /// Label of the add button.
  static const String _addText = 'Add';

  final VoidCallback onPressed;

  const _AddButtonWidget({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isRunning = context.select<NoteActionsCubit, bool>(_isRunning);
    return ElevatedButton(
      onPressed: isRunning ? null : onPressed,
      child: const Text(_addText),
    );
  }

  static bool _isRunning(NoteActionsCubit cubit) => cubit.state.isRunning;
}
