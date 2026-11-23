/// A failure that is only a human-readable text — for an app in one language, with no
/// translations.
///
/// `Result<void, TextOnlyFailure>` keeps the text in the data layer, the way it is shown.
/// An app with translations uses a failure enum per feature instead
/// (`rules/errors_models/result.md`).
final class TextOnlyFailure {
  /// The text shown to the user.
  final String text;

  /// Creates a failure with [text].
  const TextOnlyFailure(this.text);

  @override
  String toString() => text;
}
