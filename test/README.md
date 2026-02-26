# Prosepal Test Strategy

## Testing Philosophy

> "A test that doesn't give you confidence the app works is worse than no test - it gives false confidence."

## Test Pyramid for Flutter Apps

```
                 /\
                /  \   E2E (5-10 critical flows)
               /----\  
              /      \   Widget Integration (20-30 screen tests)
             /--------\
            /          \   Unit Tests (50+ for pure logic)
           --------------
```

## Test Categories

### 1. Unit Tests (`test/unit/`)
**Purpose:** Test pure logic with no dependencies
**Confidence Level:** Medium (logic works, but doesn't prove UI works)

**What to test:**
- Models (serialization, equality, validation)
- Pure functions (formatters, parsers, calculators)
- Business logic that doesn't touch UI or services

**Example:**
```dart
test('Occasion.birthday has correct emoji', () {
  expect(Occasion.birthday.emoji, equals('🎂'));
});
```

### 2. Widget Tests (`test/widgets/`)
**Purpose:** Verify screens render without crashing
**Confidence Level:** High (UI renders, interactions work)

**What to test:**
- Each screen renders with mock providers
- Buttons are tappable
- Navigation triggers correctly
- Error states display properly

**Example:**
```dart
testWidgets('HomeScreen shows all occasions', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...],
      child: MaterialApp(home: HomeScreen()),
    ),
  );
  
  for (final occasion in Occasion.values) {
    expect(find.text(occasion.label), findsOneWidget);
  }
});
```

### 3. Integration Tests (`test/integration/`)
**Purpose:** Test multi-screen user flows
**Confidence Level:** High (flows work end-to-end in test environment)

**What to test:**
- Complete user journeys with mocked services
- Navigation between screens
- State persistence across screens

**Example:**
```dart
testWidgets('Generation flow: home -> generate -> results', (tester) async {
  // Setup: Mock AI service to return test messages
  // 1. Tap "Birthday" on HomeScreen
  // 2. Verify GenerateScreen appears
  // 3. Select relationship, tone
  // 4. Tap "Generate"
  // 5. Verify ResultsScreen shows 3 messages
});
```

### 4. E2E Tests (`integration_test/`)
**Purpose:** Test on real device with real APIs
**Confidence Level:** HIGHEST (actual app works for users)

**What to test:**
- App launches without crash
- Auth flow works (if possible in test environment)
- Critical happy paths with real API calls
- Subscription flow (using sandbox)

**Run with:**
```bash
flutter test integration_test/app_test.dart
```

## Critical User Flows to Test

### Flow 1: First-Time User
1. App launches → Onboarding appears
2. Complete onboarding → Home screen appears
3. All 10 occasions visible and tappable

### Flow 2: Message Generation (MOST CRITICAL)
1. Tap occasion → GenerateScreen appears
2. Select relationship → Continue enabled
3. Select tone → Continue enabled
4. Enter details (optional) → Generate button visible
5. Tap Generate → Loading overlay appears
6. Results appear → 3 message cards visible
7. Tap copy → Clipboard contains message

### Flow 3: Free Limit & Paywall
1. Use 3 free generations
2. 4th attempt → "Upgrade to Continue" button
3. Tap upgrade → Paywall appears
4. Subscription options visible

### Flow 4: Settings & Account
1. Navigate to Settings
2. All sections render
3. Legal links work
4. Sign out works

## Test File Structure

```
test/
├── README.md                    # This file
├── unit/
│   ├── models/                  # Model tests
│   │   ├── occasion_test.dart
│   │   ├── relationship_test.dart
│   │   └── tone_test.dart
│   └── helpers/                 # Pure function tests
│       └── formatters_test.dart
├── widgets/
│   ├── screens/                 # Screen render tests
│   │   ├── home_screen_test.dart
│   │   ├── generate_screen_test.dart
│   │   ├── results_screen_test.dart
│   │   └── settings_screen_test.dart
│   └── components/              # Shared component tests
│       ├── occasion_grid_test.dart
│       └── message_card_test.dart
├── integration/
│   ├── generation_flow_test.dart
│   └── subscription_flow_test.dart
├── mocks/
│   ├── mock_providers.dart      # Riverpod overrides
│   ├── mock_ai_service.dart
│   └── mock_subscription_service.dart
└── fixtures/
    └── test_data.dart           # Reusable test data

integration_test/
├── app_test.dart                # E2E tests (run on device)
└── screenshots/                 # For App Store screenshots
```

## Running Tests

```bash
# All unit/widget tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/widgets/screens/home_screen_test.dart

# E2E tests (requires device/simulator)
flutter test integration_test/app_test.dart

# E2E with screenshots
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

## Test Confidence Levels

| Test Type | What It Proves | Confidence |
|-----------|----------------|------------|
| Unit (models) | Data structures work | ⭐⭐ |
| Unit (logic) | Business rules correct | ⭐⭐⭐ |
| Widget (render) | Screen doesn't crash | ⭐⭐⭐ |
| Widget (interaction) | Buttons work | ⭐⭐⭐⭐ |
| Integration (flow) | Multi-screen journey works | ⭐⭐⭐⭐ |
| E2E (real APIs) | Actual app works for users | ⭐⭐⭐⭐⭐ |

## Third-Party Service Testing

### Supabase Testing
**Package:** `mock_supabase_http_client` (already integrated)

```dart
// Setup in test
late MockSupabaseHttpClient mockHttpClient;
late SupabaseClient mockSupabase;

setUpAll(() {
  mockHttpClient = MockSupabaseHttpClient();
  mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );
});

tearDown(() => mockHttpClient.reset());
tearDownAll(() => mockHttpClient.close());

// Insert test data
await mockSupabase.from('profiles').insert({
  'id': 'user-123',
  'email': 'test@example.com',
});

// Query and assert
final response = await mockSupabase
    .from('profiles')
    .select()
    .eq('id', 'user-123');
expect(response[0]['email'], equals('test@example.com'));
```

### RevenueCat Testing

**API Key Usage (CRITICAL):**

| Environment | API Key | Use Case | Charges? |
|-------------|---------|----------|----------|
| **Unit Tests / CI** | Test Store (`test_xxx`) | Automated, deterministic | No |
| **Manual Device Testing** | Production (`appl_xxx`) | Apple Sandbox testers | No |
| **TestFlight** | Production (`appl_xxx`) | Beta users | No |
| **Production** | Production (`appl_xxx`) | Live users only | Yes |

```dart
// ✅ CORRECT: Test Store for ALL automated tests
static const _testStoreKey = 'test_iCdJYZJvbduyqGECAsUtDJKYClX';

// ✅ CORRECT: Production key for manual sandbox testing
static const _iosProductionKey = 'appl_dWOaTNoefQCZUxqvQfsTPuMqYuk';

// ⚠️ NEVER use production key for automated/CI tests!
// Real charges possible, dashboard pollution
```

**Debug Logging (enable BEFORE configure):**
```dart
await Purchases.setLogLevel(LogLevel.debug);
// Look for [Purchases] prefix with emojis:
// 😻 = Success | 💰 = Products | ‼️ = Error | ⚠️ = Warning
```

**Sandbox Subscription Renewals:**
| Duration | Sandbox | TestFlight (Dec 2024+) |
|----------|---------|------------------------|
| 1 week   | 3 min   | 1 day |
| 1 month  | 5 min   | 1 day |
| 1 year   | 1 hour  | 1 day |

Max 12 renewals per day in sandbox.

**Apple Sandbox Setup (Manual Testing):**
1. Create sandbox tester: App Store Connect > Users and Access > Sandbox Testers
2. Add to device: Settings > Developer > Sandbox Apple Account (iOS 18+)
3. Run app from Xcode with production key, purchase with sandbox account
4. Verify transaction in RevenueCat dashboard (enable "View Sandbox Data")

**Manual Verification Checklist:**
- [ ] Offerings load (no "Invalid Product Identifiers" in logs)
- [ ] Purchase grants 'pro' entitlement
- [ ] Restore purchases works after reinstall
- [ ] Subscription expiration revokes access
- [ ] Transactions appear in RevenueCat dashboard

### Firebase Crashlytics Testing

**Force Test Crash:**
```dart
// CAUTION: Will crash the app!
FirebaseCrashlytics.instance.crash();
```

**Log Non-Fatal Error:**
```dart
await FirebaseCrashlytics.instance.recordError(
  Exception('Test error'),
  StackTrace.current,
  reason: 'Testing Crashlytics',
  fatal: false,
);
```

**Verification Steps:**
1. Force a test crash (or log non-fatal error)
2. Relaunch the app (crash reports sent on next launch)
3. Check Firebase Console > Crashlytics (5-10 min delay)

**Run Integration Tests:**
```bash
flutter test integration_test/firebase_test.dart
```

### Firebase Analytics DebugView

**iOS Setup (Xcode):**
1. Product > Scheme > Edit Scheme
2. Select "Run" > "Arguments" tab
3. Add argument: `-FIRDebugEnabled`

**Android Setup (Terminal):**
```bash
adb shell setprop debug.firebase.analytics.app com.prosepal.prosepal
```

**Disable Debug Mode:**
- iOS: Add `-FIRDebugDisabled`
- Android: `adb shell setprop debug.firebase.analytics.app .none.`

**Verification:**
1. Enable DebugView with above steps
2. Open Firebase Console > Analytics > DebugView
3. Trigger events in app
4. See real-time events in console (up to 15 sec delay)

## Pre-Release Checklist

Before submitting to App Store:

- [ ] All unit tests pass (`flutter test`)
- [ ] All widget tests pass
- [ ] All integration tests pass
- [ ] E2E test passes on real device
- [ ] Manual smoke test of critical flows
- [ ] Test on oldest supported iOS version
- [ ] Test on smallest supported screen size

### RevenueCat Launch Checklist
- [ ] **CRITICAL: Verify using platform-specific API key, NOT Test Store key**
- [ ] Test with real Apple Sandbox (not Test Store) before submission
- [ ] Create sandbox tester account in App Store Connect
- [ ] Add sandbox account to device: Settings > Developer > Sandbox Apple Account
- [ ] Verify all products fetch correctly (check debug logs for "Invalid Product Identifiers")
- [ ] Test purchase unlocks "pro" content
- [ ] Verify subscription status updates when returning to app
- [ ] Test subscription expiration revokes access
- [ ] Test restore purchases after app reinstall
- [ ] Verify transactions appear in RevenueCat dashboard (enable "View Sandbox Data")
- [ ] Include auto-renewing subscription disclosure in App Store description
- [ ] Wait ~24 hours after "Cleared for Sale" before public release (new products propagation)
- [ ] Configure Android key before Play Store release

### Firebase Checklist
- [ ] Force test crash and verify in Crashlytics console
- [ ] Log test event and verify in Analytics DebugView
- [ ] Disable debug mode before release build
- [ ] Verify crash reports contain useful context (custom keys)
