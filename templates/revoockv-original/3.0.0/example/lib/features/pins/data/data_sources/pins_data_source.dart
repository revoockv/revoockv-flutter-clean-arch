import '../models/pin_model.dart';

/// Where the pins are stored. Every method throws the storage exception when it fails.
abstract interface class PinsDataSource {
  /// The pins now and after every change.
  Stream<List<PinModel>> watchPins();

  /// Stores [pin].
  Future<void> add(PinModel pin);

  /// Removes the pin of the note [noteId].
  Future<void> remove(String noteId);
}
