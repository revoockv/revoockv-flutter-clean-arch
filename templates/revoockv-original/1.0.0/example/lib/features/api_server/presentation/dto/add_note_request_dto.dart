/// Body of `POST /notes`: `{"text": "..."}`.
final class AddNoteRequestDto {
  static const String _textKey = 'text';

  /// Text of the new note, not validated yet — the use case validates it.
  final String text;

  /// Creates the request.
  const AddNoteRequestDto({required this.text});

  /// Reads the request from [json]; `null` when `text` is missing or not a string.
  static AddNoteRequestDto? fromJson(Map<String, Object?> json) {
    final Object? text = json[_textKey];
    return text is String ? AddNoteRequestDto(text: text) : null;
  }
}
