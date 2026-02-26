import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simple app launches', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Test App')),
          body: const Center(child: Text('Hello Test')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test App'), findsOneWidget);
    expect(find.text('Hello Test'), findsOneWidget);
  });
}
