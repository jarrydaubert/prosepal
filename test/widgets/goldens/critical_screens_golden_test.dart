import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:prosepal/features/auth/auth_screen.dart';
import 'package:prosepal/features/generate/generate_screen.dart';
import 'package:prosepal/features/home/home_screen.dart';
import 'package:prosepal/features/paywall/paywall_sheet.dart';
import 'package:prosepal/features/results/results_screen.dart';
import 'package:prosepal/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_ai_service.dart';
import '../../mocks/mock_auth_service.dart';
import '../../mocks/mock_biometric_service.dart';
import '../../mocks/mock_device_fingerprint_service.dart';
import '../../mocks/mock_rate_limit_service.dart';
import '../../mocks/mock_subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewportSize = Size(393, 852); // iPhone 14 style portrait baseline
  const dpr = 3.0;

  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockSubscriptionService mockSubscription;
  late MockBiometricService mockBiometric;
  late MockAiService mockAi;
  late MockDeviceFingerprintService mockFingerprint;
  late MockRateLimitService mockRateLimit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockBiometric = MockBiometricService();
    mockAi = MockAiService();
    mockFingerprint = MockDeviceFingerprintService();
    mockRateLimit = MockRateLimitService(deviceFingerprint: mockFingerprint);
  });

  tearDown(() {
    mockAuth.dispose();
    mockSubscription.dispose();
    mockBiometric.reset();
    mockAi.reset();
    mockFingerprint.reset();
    mockRateLimit.reset();
  });

  Future<void> prepareViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = Size(
      viewportSize.width * dpr,
      viewportSize.height * dpr,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpGolden(
    WidgetTester tester,
    Widget widget, {
    Duration settle = const Duration(milliseconds: 900),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(settle);
  }

  GoRouter singleRouteRouter({
    required String initialLocation,
    required Widget home,
    List<RouteBase> extraRoutes = const [],
  }) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: initialLocation, builder: (context, state) => home),
      ...extraRoutes,
    ],
  );

  GenerationResult sampleResult() {
    final now = DateTime.utc(2026, 2, 25, 12);
    return GenerationResult(
      occasion: Occasion.birthday,
      relationship: Relationship.closeFriend,
      tone: Tone.heartfelt,
      length: MessageLength.standard,
      recipientName: 'Alex',
      messages: [
        GeneratedMessage(
          id: 'm1',
          text: 'Happy birthday, Alex! Wishing you a brilliant year ahead.',
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          createdAt: now,
        ),
        GeneratedMessage(
          id: 'm2',
          text: 'Hope your day is full of joy and cake. You deserve both.',
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          createdAt: now,
        ),
        GeneratedMessage(
          id: 'm3',
          text: 'Cheers to another lap around the sun. Proud of you always.',
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          createdAt: now,
        ),
      ],
    );
  }

  testWidgets('golden: auth screen baseline', (tester) async {
    await prepareViewport(tester);

    final router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/auth/email',
          builder: (context, state) => const Scaffold(body: Text('Email')),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const Scaffold(body: Text('Terms')),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) => const Scaffold(body: Text('Privacy')),
        ),
      ],
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/auth_screen.png'),
    );
  });

  testWidgets('golden: home screen baseline', (tester) async {
    await prepareViewport(tester);

    final initStatusNotifier = InitStatusNotifier()
      ..markSupabaseReady()
      ..markRevenueCatReady()
      ..markRemoteConfigReady();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/generate',
          builder: (context, state) => const Scaffold(body: Text('Generate')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('Auth')),
        ),
      ],
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          initStatusProvider.overrideWith((ref) => initStatusNotifier),
          isProProvider.overrideWith((ref) => false),
          remainingGenerationsProvider.overrideWith((ref) => 1),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/home_screen.png'),
    );
  });

  testWidgets('golden: generate screen baseline', (tester) async {
    await prepareViewport(tester);

    final router = GoRouter(
      initialLocation: '/generate',
      routes: [
        GoRoute(
          path: '/generate',
          builder: (context, state) => const GenerateScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/results',
          builder: (context, state) => const Scaffold(body: Text('Results')),
        ),
      ],
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(mockAi),
          deviceFingerprintServiceProvider.overrideWithValue(mockFingerprint),
          rateLimitServiceProvider.overrideWithValue(mockRateLimit),
          usageServiceProvider.overrideWith(
            (ref) => UsageService(prefs, mockFingerprint, mockRateLimit),
          ),
          selectedOccasionProvider.overrideWith((ref) => Occasion.birthday),
          selectedRelationshipProvider.overrideWith(
            (ref) => Relationship.closeFriend,
          ),
          selectedToneProvider.overrideWith((ref) => Tone.heartfelt),
          isProProvider.overrideWith((ref) => false),
          remainingGenerationsProvider.overrideWith((ref) => 1),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/generate_screen.png'),
    );
  });

  testWidgets('golden: results screen baseline', (tester) async {
    await prepareViewport(tester);

    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/results',
          builder: (context, state) => const ResultsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          generationResultProvider.overrideWith((ref) => sampleResult()),
          isProProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/results_screen.png'),
    );
  });

  testWidgets('golden: settings screen baseline', (tester) async {
    await prepareViewport(tester);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/feedback',
          name: 'feedback',
          builder: (context, state) => const Scaffold(body: Text('Feedback')),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const Scaffold(body: Text('Terms')),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) => const Scaffold(body: Text('Privacy')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('Auth')),
        ),
      ],
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          biometricServiceProvider.overrideWithValue(mockBiometric),
          isProProvider.overrideWith((ref) => false),
          remainingGenerationsProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/settings_screen.png'),
    );
  });

  testWidgets('golden: paywall sheet baseline', (tester) async {
    await prepareViewport(tester);

    mockSubscription.setConfigured(false);

    final router = singleRouteRouter(
      initialLocation: '/paywall',
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: PaywallSheet(source: 'golden')),
      ),
    );

    await pumpGolden(
      tester,
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
      settle: const Duration(seconds: 2),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/critical/paywall_sheet.png'),
    );
  });
}
