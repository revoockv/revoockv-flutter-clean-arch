/// What can go wrong with the pins; the presentation layer turns it into text.
enum PinFailure {
  /// A note could not be pinned or unpinned.
  toggle,

  /// The pins could not be loaded.
  load,
}
