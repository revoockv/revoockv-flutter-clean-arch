import 'package:example_app/features/api_server/presentation/pages/api_server_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import '../api_server_test_di.dart';
import '../fake_api_server_data_sources.dart';

void main() {
  tearDown(() async => di.reset());

  testWidgets('the switch starts and stops the server', (WidgetTester tester) async {
    final FakeApiServerDataSource dataSource = FakeApiServerDataSource();
    await registerAndInitApiServerForTest(dataSource);
    await tester.pumpWidget(const MaterialApp(home: ApiServerPage()));
    expect(find.text('Off'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(dataSource.listening, isTrue);
    expect(find.textContaining('Port 8080 · token '), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(dataSource.listening, isFalse);
    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('a taken port shows the failure', (WidgetTester tester) async {
    await registerAndInitApiServerForTest(BusyPortApiServerDataSource());
    await tester.pumpWidget(const MaterialApp(home: ApiServerPage()));

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('Could not start the server — is the port taken?'), findsOneWidget);
  });
}
