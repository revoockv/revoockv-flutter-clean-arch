import '../../domain/entities/pin_failure.dart';

/// The text of a [PinFailure] shown to the user.
extension PinFailureText on PinFailure {
  static const String _toggle = 'Could not pin the note';
  static const String _load = 'Could not load the pins';

  /// The human-readable text of this failure.
  String get text => switch (this) {
    PinFailure.toggle => _toggle,
    PinFailure.load => _load,
  };
}
