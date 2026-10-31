/// JSON body of every failed response: `{"error": "<human-readable text>"}`.
final class ErrorDto {
  /// JSON key of the error text.
  static const String _errorKey = 'error';

  /// Human-readable error text.
  final String error;

  /// Creates the error body.
  const ErrorDto(this.error);

  /// Converts the body into JSON.
  Map<String, Object?> toJson() => <String, Object?>{_errorKey: error};
}
