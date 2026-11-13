import 'package:example_app/core/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app_test_app.dart';
import '../../settle.dart';

void main() {
  testWidgets('a note added on the Notes tab is counted on the Statistics tab', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(const HomePage()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await settle(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Statistics'));
    await settle(tester);
    expect(find.widgetWithText(AppBar, 'Statistics'), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(ListTile, 'Words'), matching: find.text('2')), findsOneWidget);
  });
}
