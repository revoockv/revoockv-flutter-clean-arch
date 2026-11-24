import 'package:example_app/features/notes/presentation/pages/notes_page.dart';
import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/home_tab_cubit.dart';

/// The app's shell: the Notes and Statistics tabs. Both stay alive while the other is shown.
final class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BlocProvider<HomeTabCubit>(create: _createHomeTabCubit, child: _HomeViewWidget());
  }

  static HomeTabCubit _createHomeTabCubit(BuildContext context) => HomeTabCubit();
}

/// The tabs; rebuilds only when another tab is chosen.
final class _HomeViewWidget extends StatelessWidget {
  static const String _notesLabel = 'Notes';
  static const String _statisticsLabel = 'Statistics';

  const _HomeViewWidget();

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
