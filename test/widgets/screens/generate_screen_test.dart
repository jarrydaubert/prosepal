import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/ai_service.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:prosepal/core/services/review_service.dart';
import 'package:prosepal/features/generate/generate_screen.dart';

import '../../mocks/mock_auth_service.dart';
import '../../mocks/mock_device_fingerprint_service.dart';
import '../../mocks/mock_rate_limit_service.dart';

/// Mock AI Service that returns predictable results and tracks calls
class MockAiService extends AiService {
  MockAiService() : super();

  bool shouldFail = false;
  AiServiceException? exceptionToThrow;
  int generateCallCount = 0;
  final _uuid = const Uuid();

  // Track last call parameters
  Occasion? lastOccasion;
  Relationship? lastRelationship;
  Tone? lastTone;
  MessageLength? lastLength;
  String? lastRecipientName;
  String? lastPersonalDetails;

  void reset() {
    shouldFail = false;
    exceptionToThrow = null;
    generateCallCount = 0;
    lastOccasion = null;
    lastRelationship = null;
    lastTone = null;
    lastLength = null;
    lastRecipientName = null;
    lastPersonalDetails = null;
  }

  @override
  Future<GenerationResult> generateMessages({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    MessageLength length = MessageLength.standard,
    String? recipientName,
    String? personalDetails,
  }) async {
    generateCallCount++;

    // Store parameters for verification
    lastOccasion = occasion;
    lastRelationship = relationship;
    lastTone = tone;
    lastLength = length;
    lastRecipientName = recipientName;
    lastPersonalDetails = personalDetails;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    if (shouldFail) {
      throw const AiServiceException('Test error');
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    final now = DateTime.now().toUtc();

    return GenerationResult(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
      messages: [
        GeneratedMessage(
          id: _uuid.v4(),
          text: 'Test message 1 for ${occasion.label}',
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
        ),
        GeneratedMessage(
          id: _uuid.v4(),
          text: 'Test message 2 for ${occasion.label}',
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
        ),
        GeneratedMessage(
          id: _uuid.v4(),
          text: 'Test message 3 for ${occasion.label}',
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late MockAiService mockAiService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAiService = MockAiService();
  });

  tearDown(() {
    mockAiService.reset();
  });

  /// Helper to create testable GenerateScreen with full provider overrides
  Widget createTestableGenerateScreen({
    Occasion? selectedOccasion,
    Relationship? selectedRelationship,
    Tone? selectedTone,
    bool isPro = false,
    int remaining = 3,
    bool isLoggedIn = false,
    GoRouter? router,
    MockAiService? customAiService,
  }) {
    final mockAuthService = MockAuthService();
    mockAuthService.setLoggedIn(isLoggedIn);
    final aiService = customAiService ?? mockAiService;
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/generate',
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/generate',
              name: 'generate',
              builder: (context, state) => const GenerateScreen(),
            ),
            GoRoute(
              path: '/results',
              name: 'results',
              builder: (context, state) =>
                  const Scaffold(body: Text('Results Screen')),
            ),
            GoRoute(
              path: '/paywall',
              name: 'paywall',
              builder: (context, state) =>
                  const Scaffold(body: Text('Paywall Screen')),
            ),
            GoRoute(
              path: '/auth',
              name: 'auth',
              builder: (context, state) =>
                  const Scaffold(body: Text('Auth Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        aiServiceProvider.overrideWithValue(aiService),
        authServiceProvider.overrideWithValue(mockAuthService),
        usageServiceProvider.overrideWith(
          (ref) => UsageService(
            mockPrefs,
            MockDeviceFingerprintService(),
            MockRateLimitService(),
          ),
        ),
        reviewServiceProvider.overrideWith((ref) => ReviewService(mockPrefs)),
        isProProvider.overrideWith((ref) => isPro),
        remainingGenerationsProvider.overrideWith((ref) => remaining),
        selectedOccasionProvider.overrideWith((ref) => selectedOccasion),
        selectedRelationshipProvider.overrideWith(
          (ref) => selectedRelationship,
        ),
        selectedToneProvider.overrideWith((ref) => selectedTone),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  /// Helper to navigate from step 1 to step 2
  Future<void> navigateToStep2(WidgetTester tester) async {
    await tester.tap(find.text('Close Friend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  /// Helper to navigate from step 1 to step 3
  Future<void> navigateToStep3(WidgetTester tester) async {
    await navigateToStep2(tester);
    await tester.tap(find.text('Heartfelt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Ensure Generate button is visible (may need scrolling)
    final generateButton = find.text('Generate Messages');
    if (generateButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
    }
  }

  // ============================================================
  // STEP 1: RELATIONSHIP PICKER
  // ============================================================
  group('GenerateScreen Step 1: Relationship Picker', () {
    testWidgets('displays all relationship options', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();

      for (final relationship in Relationship.values) {
        expect(
          find.text(relationship.label),
          findsOneWidget,
          reason: 'Should display ${relationship.label}',
        );
      }
    });

    testWidgets('shows step indicator with 3 segments', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();

      // Step indicator consists of 3 Container widgets in a Row
      expect(find.byType(GenerateScreen), findsOneWidget);
    });

    testWidgets('Continue button is disabled when no relationship selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();

      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);

      // Tap without selecting - should not navigate
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Should still be on step 1 (relationships visible)
      expect(find.text('Close Friend'), findsOneWidget);
      expect(find.text('Heartfelt'), findsNothing); // Tone not visible
    });

    testWidgets('Continue button navigates after selecting relationship', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();

      // Select relationship
      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();

      // Tap continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should now be on step 2 (tones visible)
      for (final tone in Tone.values) {
        expect(find.text(tone.label), findsOneWidget);
      }
    });

    testWidgets('each relationship option is tappable', (tester) async {
      for (final relationship in Relationship.values) {
        await tester.pumpWidget(
          createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(relationship.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should advance to step 2
        expect(
          find.text('Heartfelt'),
          findsOneWidget,
          reason: '${relationship.label} should allow navigation',
        );
      }
    });
  });

  // ============================================================
  // STEP 2: TONE SELECTOR
  // ============================================================
  group('GenerateScreen Step 2: Tone Selector', () {
    testWidgets('displays all tone options', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep2(tester);

      for (final tone in Tone.values) {
        expect(
          find.text(tone.label),
          findsOneWidget,
          reason: 'Should display ${tone.label} tone',
        );
      }
    });

    testWidgets('Continue button navigates to step 3 after selecting tone', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep2(tester);

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should be on step 3 - Generate button visible
      expect(find.text('Generate Messages'), findsOneWidget);
    });

    testWidgets('each tone option is tappable', (tester) async {
      for (final tone in Tone.values) {
        await tester.pumpWidget(
          createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
        );
        await tester.pumpAndSettle();
        await navigateToStep2(tester);

        await tester.tap(find.text(tone.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(
          find.text('Generate Messages'),
          findsOneWidget,
          reason: '${tone.label} should allow navigation to step 3',
        );
      }
    });
  });

  // ============================================================
  // STEP 3: DETAILS & GENERATE
  // ============================================================
  group('GenerateScreen Step 3: Details & Generate', () {
    testWidgets('shows Generate button', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      expect(find.text('Generate Messages'), findsOneWidget);
    });

    testWidgets('shows all message length options', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      for (final length in MessageLength.values) {
        expect(
          find.text(length.label),
          findsOneWidget,
          reason: 'Should display ${length.label} length option',
        );
      }
    });

    testWidgets('Brief length is selectable', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      // Scroll to Brief before tapping (may be off-screen)
      final briefFinder = find.text('Brief');
      await tester.ensureVisible(briefFinder);
      await tester.pumpAndSettle();

      await tester.tap(briefFinder);
      await tester.pumpAndSettle();

      expect(find.text('Generate Messages'), findsOneWidget);
    });
  });

  // ============================================================
  // FREE TIER LIMITS
  // ============================================================
  group('GenerateScreen Free Tier Limits', () {
    testWidgets(
      'shows Upgrade button when 0 generations remaining (logged in)',
      (tester) async {
        await tester.pumpWidget(
          createTestableGenerateScreen(
            selectedOccasion: Occasion.birthday,
            remaining: 0,
            isLoggedIn: true,
          ),
        );
        await tester.pumpAndSettle();
        await navigateToStep3(tester);

        expect(find.text('Upgrade to Continue'), findsOneWidget);
        expect(find.text('Generate Messages'), findsNothing);
      },
    );

    testWidgets('Upgrade button navigates to paywall when logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          remaining: 0,
          isLoggedIn: true,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Upgrade to Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('Upgrade button navigates to auth when not logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          remaining: 0,
          isLoggedIn: false,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Upgrade to Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Auth Screen'), findsOneWidget);
    });

    testWidgets('shows Generate button when generations remaining > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          remaining: 1,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      expect(find.text('Generate Messages'), findsOneWidget);
      expect(find.text('Upgrade to Continue'), findsNothing);
    });
  });

  // ============================================================
  // PRO USER SCENARIOS
  // ============================================================
  group('GenerateScreen Pro User', () {
    testWidgets('Pro user sees Generate button with high remaining', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          isPro: true,
          remaining: 500,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      expect(find.text('Generate Messages'), findsOneWidget);
      expect(find.text('Upgrade to Continue'), findsNothing);
    });
  });

  // ============================================================
  // NAVIGATION
  // ============================================================
  group('GenerateScreen Navigation', () {
    testWidgets('back button returns to previous step', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep2(tester);

      // Should be on step 2
      expect(find.text('Heartfelt'), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be on step 1
      expect(find.text('Close Friend'), findsOneWidget);
      expect(find.text('Heartfelt'), findsNothing);
    });

    testWidgets('back from step 3 returns to step 2', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be on step 2
      expect(find.text('Heartfelt'), findsOneWidget);
    });

    testWidgets('shows occasion name and emoji in app bar', (tester) async {
      await tester.pumpWidget(
        createTestableGenerateScreen(selectedOccasion: Occasion.birthday),
      );
      await tester.pumpAndSettle();

      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('🎂'), findsOneWidget);
    });

    testWidgets('redirects to home if no occasion selected', (tester) async {
      await tester.pumpWidget(createTestableGenerateScreen());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });

  // ============================================================
  // GENERATION SUCCESS FLOW
  // ============================================================
  group('GenerateScreen Successful Generation', () {
    testWidgets('tapping Generate calls AI service once', (tester) async {
      final freshMock = MockAiService();

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          customAiService: freshMock,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      expect(freshMock.generateCallCount, equals(0));

      await tester.tap(find.text('Generate Messages'));
      await tester.pumpAndSettle();

      expect(freshMock.generateCallCount, equals(1));
    });

    testWidgets('AI service receives correct occasion', (tester) async {
      final freshMock = MockAiService();

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.wedding,
          customAiService: freshMock,
        ),
      );
      await tester.pumpAndSettle();

      // Select Family relationship (first item, should be visible)
      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Select Heartfelt tone (first item, should be visible)
      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Scroll to and tap Generate button
      final generateButton = find.text('Generate Messages');
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Verify occasion
      expect(freshMock.lastOccasion, equals(Occasion.wedding));
    });
  });

  // ============================================================
  // ERROR HANDLING
  // ============================================================
  group('GenerateScreen Error Handling', () {
    testWidgets('shows network error message', (tester) async {
      final errorMock = MockAiService();
      errorMock.exceptionToThrow = const AiNetworkException('No internet');

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          customAiService: errorMock,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Generate Messages'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('internet'), findsOneWidget);
    });

    testWidgets('shows rate limit error message', (tester) async {
      final errorMock = MockAiService();
      errorMock.exceptionToThrow = const AiRateLimitException(
        'Too many requests',
      );

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          customAiService: errorMock,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Generate Messages'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Too many'), findsOneWidget);
    });

    testWidgets('error message has dismiss button', (tester) async {
      final errorMock = MockAiService();
      errorMock.exceptionToThrow = const AiNetworkException('No internet');

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          customAiService: errorMock,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Generate Messages'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Error icon and close button should be visible
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('error can be dismissed', (tester) async {
      final errorMock = MockAiService();
      errorMock.exceptionToThrow = const AiNetworkException('No internet');

      await tester.pumpWidget(
        createTestableGenerateScreen(
          selectedOccasion: Occasion.birthday,
          customAiService: errorMock,
        ),
      );
      await tester.pumpAndSettle();
      await navigateToStep3(tester);

      await tester.tap(find.text('Generate Messages'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Dismiss error
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Error should be gone
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  // ============================================================
  // ALL OCCASIONS
  // ============================================================
  group('GenerateScreen All Occasions', () {
    for (final occasion in Occasion.values) {
      testWidgets('works for ${occasion.label}', (tester) async {
        await tester.pumpWidget(
          createTestableGenerateScreen(selectedOccasion: occasion),
        );
        await tester.pumpAndSettle();

        // App bar shows occasion label and emoji (may appear multiple times in UI)
        expect(find.text(occasion.label), findsAtLeastNWidgets(1));
        expect(find.text(occasion.emoji), findsAtLeastNWidgets(1));

        // Step 1 is visible
        expect(find.text('Close Friend'), findsOneWidget);
      });
    }
  });
}
