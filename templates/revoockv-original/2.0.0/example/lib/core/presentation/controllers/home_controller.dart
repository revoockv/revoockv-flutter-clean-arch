import 'package:flutter/foundation.dart' show ValueNotifier;

/// UI state of the home page: which tab is shown.
final class HomeController {
  /// Index of the selected tab.
  final ValueNotifier<int> selectedTabController = ValueNotifier<int>(0);

  /// Releases the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    selectedTabController.dispose();
  }
}
