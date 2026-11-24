import 'package:flutter/foundation.dart' show setEquals;

/// The notes the user pinned to the top, by note id.
///
/// Compared by value, so a selection of it rebuilds only when the pins really change.
final class PinnedNotes {
  /// No pinned notes.
  static const PinnedNotes none = PinnedNotes(<String>{});

  final Set<String> _noteIds;

  /// Creates the pins of [noteIds].
  const PinnedNotes(Set<String> noteIds) : _noteIds = noteIds;

  /// Whether the note [noteId] is pinned.
  bool contains(String noteId) => _noteIds.contains(noteId);

  /// How many of [noteIds] are pinned — a pin of a deleted note does not count.
  int countAmong(Iterable<String> noteIds) => noteIds.where(contains).length;

  @override
  bool operator ==(Object other) => other is PinnedNotes && setEquals(other._noteIds, _noteIds);

  @override
  int get hashCode => Object.hashAllUnordered(_noteIds);
}
