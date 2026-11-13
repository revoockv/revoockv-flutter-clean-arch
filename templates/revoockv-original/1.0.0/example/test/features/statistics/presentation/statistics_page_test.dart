import 'package:example_app/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import '../../../app_test_di.dart';
import '../../../settle.dart';

void main() {
  tearDown(() async => di.reset());

  testWidgets('shows the numbers of an empty app', (WidgetTester tester) async {
    await registerAndInitForTest();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatisticsPage())));
    await settle(tester);

    for (final String label in <String>['Notes', 'Words', 'Added today', 'Edited']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    expect(find.text('0'), findsNWidgets(4));
    await tester.pumpWidget(const SizedBox());
  });
}
