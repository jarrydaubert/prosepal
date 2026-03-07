/// Firebase Test Lab Integration Tests (critical deterministic subset)
///
/// This suite is intentionally small and deterministic for virtualized Android
/// device execution in Firebase Test Lab.
///
/// Build:
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     flutter build apk --debug -t integration_test/ftl_test.dart
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     (cd android && ./gradlew app:assembleAndroidTest \
///       -Ptarget=../integration_test/ftl_test.dart)
///
/// Run on FTL:
///   gcloud firebase test android run \
///     --type instrumentation \
///     --app build/app/outputs/flutter-apk/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33,locale=en,orientation=portrait \
///     --timeout 12m \
///     --no-use-orchestrator
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_deterministic_app_harness.dart';

late IntegrationTestWidgetsFlutterBinding binding;

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FTL Critical', () {
    late DeterministicAppHarness harness;

    setUp(() async {
      harness = await DeterministicAppHarness.create(loggedIn: true);
    });

    Future<void> pumpUntilVisible(
      WidgetTester tester,
      Finder finder, {
      int maxTicks = 30,
      Duration step = const Duration(milliseconds: 200),
    }) async {
      for (var i = 0; i < maxTicks; i++) {
        if (finder.evaluate().isNotEmpty) {
          return;
        }
        await tester.pump(step);
      }
      fail('Timed out waiting for expected widget');
    }

    Future<void> pumpUntilAnyVisible(
      WidgetTester tester,
      List<Finder> finders, {
      int maxTicks = 30,
      Duration step = const Duration(milliseconds: 200),
    }) async {
      for (var i = 0; i < maxTicks; i++) {
        if (finders.any((finder) => finder.evaluate().isNotEmpty)) {
          return;
        }
        await tester.pump(step);
      }
      fail('Timed out waiting for any expected widget');
    }

    void registerAppCleanup(WidgetTester tester) {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        harness.dispose();
      });
    }

    testWidgets('S1: Launches and renders home', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(harness.buildApp());
      await pumpUntilAnyVisible(tester, [
        find.text("What's the occasion?"),
        find.text('Birthday'),
        find.byKey(const ValueKey('home_settings_button')),
      ]);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('S2: Occasion opens wizard', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(harness.buildApp());
      await pumpUntilVisible(tester, find.text('Birthday'));

      await tester.tap(find.text('Birthday'));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Close Friend'));
      expect(find.text('Close Friend'), findsOneWidget);
    });

    testWidgets('S3: Settings open and return', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(harness.buildApp());
      await pumpUntilVisible(tester, find.byIcon(Icons.settings_outlined));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Settings'));
      expect(find.text('Settings'), findsOneWidget);

      final canonicalBack = find.byIcon(Icons.chevron_left_rounded);
      final fallbackBack = find.byTooltip('Back');
      expect(
        canonicalBack.evaluate().isNotEmpty ||
            fallbackBack.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected a back affordance on the settings screen',
      );
      await tester.tap(
        canonicalBack.evaluate().isNotEmpty ? canonicalBack : fallbackBack,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Birthday'));
    });

    testWidgets('S4: Pro override renders without crash', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(harness.buildApp(isPro: true));
      await pumpUntilAnyVisible(tester, [
        find.text("What's the occasion?"),
        find.text('Birthday'),
        find.byKey(const ValueKey('home_settings_button')),
      ]);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
