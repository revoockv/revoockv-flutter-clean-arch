import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/home_tab_cubit.dart';
import 'home_view.dart';

/// The app's shell: provides the tab cubit to [HomeView], which shows the Notes and Statistics tabs.
final class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BlocProvider<HomeTabCubit>(create: _createHomeTabCubit, child: HomeView());
  }

  static HomeTabCubit _createHomeTabCubit(BuildContext context) => HomeTabCubit();
}
