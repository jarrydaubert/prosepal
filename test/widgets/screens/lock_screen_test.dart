import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:prosepal/features/auth/lock_screen.dart';

/// LockScreen Widget Tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestableLockScreen({GoRouter? router}) {
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/lock',
          routes: [
            GoRoute(
              path: '/lock',
              builder: (context, state) => const LockScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        );

    return MaterialApp.router(routerConfig: testRouter);
  }

  group('LockScreen', () {
    testWidgets('has retry option after biometric failure', (tester) async {
      // BUG: User stuck forever after failed biometric - must uninstall app
      await tester.pumpWidget(createTestableLockScreen());
      await tester.pump(const Duration(milliseconds: 500));

      final hasRetry =
          find.textContaining('Unlock').evaluate().isNotEmpty ||
          find.textContaining('Tap').evaluate().isNotEmpty ||
          find.textContaining('Try').evaluate().isNotEmpty ||
          find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(FilledButton).evaluate().isNotEmpty;

      expect(hasRetry, isTrue);
    });

    testWidgets('does not bypass lock without authentication', (tester) async {
      // BUG: Security vulnerability - app content accessible without auth
      await tester.pumpWidget(createTestableLockScreen());
      await tester.pump(const Duration(seconds: 1));

      // Should NOT navigate to home without successful auth
      expect(find.text('Home Screen'), findsNothing);
    });
  });
}
