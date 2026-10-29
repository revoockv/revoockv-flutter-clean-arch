import 'dart:async';

/// A class that owns resources (subscriptions, controllers, connections) and must release them.
abstract interface class DisposableResource {
  /// Releases every resource the class owns. Called by DI, never by UI or use cases.
  FutureOr<void> dispose();
}
