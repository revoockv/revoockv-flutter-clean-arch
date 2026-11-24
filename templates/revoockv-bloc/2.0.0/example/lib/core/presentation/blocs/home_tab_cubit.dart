import 'package:flutter_bloc/flutter_bloc.dart';

/// Which tab of the home page is shown (its index).
final class HomeTabCubit extends Cubit<int> {
  /// Starts on the first tab.
  HomeTabCubit() : super(0);

  /// Shows the tab at [index].
  void select(int index) => emit(index);
}
