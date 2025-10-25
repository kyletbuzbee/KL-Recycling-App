import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/main.dart';
import 'package:kl_recycling_app/providers/data_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const KlRecyclingApp(),
    ));

    // Verify that our app has loaded successfully
    expect(find.byType(KlRecyclingApp), findsOneWidget);

    // Wait for any async operations
    await tester.pumpAndSettle();
  });

  testWidgets('Main screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const KlRecyclingApp(),
    ));

    await tester.pumpAndSettle();

    // Verify we can find material app
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
