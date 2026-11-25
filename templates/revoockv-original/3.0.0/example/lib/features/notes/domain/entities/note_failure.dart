/// What can go wrong with notes; the presentation layer turns it into text.
enum NoteFailure {
  /// The note text is blank.
  emptyText,

  /// The note could not be added.
  add,

  /// The note could not be changed.
  update,

  /// The note could not be deleted.
  delete,

  /// The notes could not be loaded.
  load,
}
