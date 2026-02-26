/// Basic Integration Test for Prosepal
/// 
/// Minimal test to verify app launches correctly.
/// Run with: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/basic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches without error', (tester) async {
    // Launch the actual app
    app.main();
    
    // Wait for app to settle
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Just verify something renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
