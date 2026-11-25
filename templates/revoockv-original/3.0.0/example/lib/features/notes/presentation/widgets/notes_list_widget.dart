import 'package:flutter/material.dart';

/// The notes: a progress indicator while loading, the load error, a text when there are none, or one item per id.
///
/// Dumb: it gets the ids in their order and builds each item with [itemBuilder], so an item that changes rebuilds
/// alone.
final class NotesListWidget extends StatelessWidget {
  /// Whether the first notes have not arrived yet.
  final bool isLoading;

  /// The text of the load error, `null` when the notes are loaded.
  final String? failureText;

  /// Text shown when there are no notes.
  final String emptyText;

  /// Ids of the notes, newest first.
  final List<String> noteIds;

  /// Builds the item of one note; give it a key of the note id.
  final Widget Function(BuildContext context, String noteId) itemBuilder;

  /// Creates the list.
  const NotesListWidget({
    required this.isLoading,
    required this.failureText,
    required this.emptyText,
    required this.noteIds,
    required this.itemBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String? failure = failureText;
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (failure != null) return Center(child: Text(failure));
    if (noteIds.isEmpty) return Center(child: Text(emptyText));
    return ListView.builder(
      itemCount: noteIds.length,
      itemBuilder: (BuildContext context, int index) => itemBuilder(context, noteIds[index]),
    );
  }
}
