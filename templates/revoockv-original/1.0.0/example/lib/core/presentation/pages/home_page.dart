import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../controllers/home_controller.dart';

/// The app's shell: the Notes and Statistics tabs. Both stay alive while the other is shown.
final class HomePage extends WatchingWidget {
  static const String _notesLabel = 'Notes';
  static const String _statisticsLabel = 'Statistics';

  /// Creates the page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = createOnce(_createHomeController, dispose: _disposeHomeController);
    final int selectedTab = watch(homeController.selectedTabController).value;

    return Scaffold(
      appBar: AppBar(title: Text(selectedTab == 0 ? _notesLabel : _statisticsLabel)),
      body: IndexedStack(index: selectedTab, children: const <Widget>[NotesPage(), StatisticsPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (int tab) => _onTabSelected(homeController, tab),
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.notes), label: _notesLabel),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: _statisticsLabel),
        ],
      ),
    );
  }

  static HomeController _createHomeController() => HomeController();

  static void _disposeHomeController(HomeController homeController) => homeController.dispose();

  void _onTabSelected(HomeController homeController, int tab) {
    homeController.selectedTabController.value = tab;
  }
}
