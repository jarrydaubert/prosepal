import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:prosepal/features/auth/lock_screen.dart';

/// LockScreen Widget Tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, (call) async {
          switch (call.method) {
            case 'isDeviceSupported':
              return true;
            case 'getAvailableBiometrics':
              return <String>['fingerprint'];
            case 'authenticate':
              return false;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, null);
  });

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

  void testWidgetsWithCleanup(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        // Dispose route tree and flush delayed timers used by lock-screen UX.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
      }
    });
  }

  group('LockScreen', () {
    testWidgetsWithCleanup('renders lock branding and unlock action', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableLockScreen());
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text('Tap to unlock'), findsOneWidget);
      expect(find.textContaining('Unlock with'), findsOneWidget);
    });

    testWidgetsWithCleanup('shows retry hint after repeated failed attempts', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableLockScreen());
      await tester.pump(const Duration(milliseconds: 800));

      // Initial auto-attempt fails once; tap once more to cross retry threshold.
      await tester.tap(find.textContaining('Unlock with'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Having trouble?'), findsOneWidget);

      // Flush auto-dismiss timer started by LockScreen.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgetsWithCleanup('has retry option after biometric failure', (
      tester,
    ) async {
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

    testWidgetsWithCleanup('does not bypass lock without authentication', (
      tester,
    ) async {
      // BUG: Security vulnerability - app content accessible without auth
      await tester.pumpWidget(createTestableLockScreen());
      await tester.pump(const Duration(seconds: 1));

      // Should NOT navigate to home without successful auth
      expect(find.text('Home Screen'), findsNothing);
    });
  });
}
