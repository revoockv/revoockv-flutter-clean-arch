import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/home_tab_cubit.dart';

/// The Notes and Statistics tabs below [HomeTabCubit]; both stay alive while the other is shown, and only a change of
/// tab rebuilds it.
final class HomeView extends StatelessWidget {
  static const String _notesLabel = 'Notes';
  static const String _statisticsLabel = 'Statistics';

  /// Creates the view.
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final int selectedTab = context.watch<HomeTabCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(selectedTab == 0 ? _notesLabel : _statisticsLabel)),
      body: IndexedStack(index: selectedTab, children: const <Widget>[NotesPage(), StatisticsPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: context.read<HomeTabCubit>().select,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.notes), label: _notesLabel),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: _statisticsLabel),
        ],
      ),
    );
  }
}
