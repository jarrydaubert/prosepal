/// E2E Integration Tests for Prosepal
///
/// Entry point that runs all integration tests for Firebase Test Lab.
/// Uses standard Flutter integration_test (no Patrol dependency).
///
/// Test Philosophy: "What bug is this test trying to find?"
/// - Smoke tests: App won't launch at all
/// - Journey tests: User can't complete a critical flow
/// - Coverage tests: Specific option causes crash
///
/// Build for Firebase Test Lab:
///   # Android
///   flutter build apk --debug -t integration_test/e2e_test.dart
///   cd android && ./gradlew app:assembleAndroidTest
///
///   # iOS
///   flutter build ios integration_test/e2e_test.dart --release
///
/// Run locally:
///   flutter test integration_test/e2e_test.dart -d [device-id]
///
/// Test Structure:
///   smoke_test.dart              - Quick sanity (5 tests, <30s)
///   journeys/
///     j1_fresh_install_test.dart - Fresh user → free generation
///     j2_upgrade_flow_test.dart  - Free user → upgrade → purchase
///     j3_pro_generate_test.dart  - Pro user → unlimited generation
///     j4_settings_test.dart      - Account management
///     j5_navigation_test.dart    - Back button, wizard state
///     j6_error_resilience_test.dart - Rapid taps, error recovery
///     j7_restore_flow_test.dart  - Restore purchases
///     j8_paywall_test.dart       - Paywall display
///     j9_wizard_details_test.dart - Name/details customization
///     j10_results_actions_test.dart - Copy/share/regenerate
///   coverage/
///     occasions_test.dart        - All 40 occasions load
///     relationships_test.dart    - All 14 relationships work
///     tones_test.dart            - All 6 tones work
library;

// Smoke test (runs first - validates app launches)
import 'smoke_test.dart' as smoke;

// User journey tests (critical paths)
import 'journeys/j1_fresh_install_test.dart' as j1;
import 'journeys/j2_upgrade_flow_test.dart' as j2;
import 'journeys/j3_pro_generate_test.dart' as j3;
import 'journeys/j4_settings_test.dart' as j4;
import 'journeys/j5_navigation_test.dart' as j5;
import 'journeys/j6_error_resilience_test.dart' as j6;
import 'journeys/j7_restore_flow_test.dart' as j7;
import 'journeys/j8_paywall_test.dart' as j8;
import 'journeys/j9_wizard_details_test.dart' as j9;
import 'journeys/j10_results_actions_test.dart' as j10;

// Coverage tests (all options work)
import 'coverage/occasions_test.dart' as occasions;
import 'coverage/relationships_test.dart' as relationships;
import 'coverage/tones_test.dart' as tones;

void main() {
  // === SMOKE TESTS ===
  // Bug: App won't launch at all
  // Time: ~30 seconds
  smoke.main();

  // === JOURNEY TESTS ===
  // Bug: User can't complete a critical flow

  // J1: Fresh install → Free generation
  // Bug: First-time user blocked from experiencing app
  j1.main();

  // J2: Free user → Upgrade → Purchase
  // Bug: Users can't pay us (revenue impact!)
  j2.main();

  // J3: Pro user → Generate → Sign out
  // Bug: Paying customers can't use what they paid for
  j3.main();

  // J4: Settings & Account management
  // Bug: Users can't manage their account
  j4.main();

  // J5: Navigation (back, wizard state)
  // Bug: Users get stuck, can't go back
  j5.main();

  // J6: Error resilience (rapid taps, recovery)
  // Bug: App crashes under normal user behavior
  j6.main();

  // J7: Restore purchases
  // Bug: Users who reinstall lose their subscription
  j7.main();

  // J8: Paywall display
  // Bug: Paywall broken, users can't see pricing
  j8.main();

  // J9: Wizard details (name, personal details)
  // Bug: Customization features don't work
  j9.main();

  // J10: Results actions (copy, share, regenerate)
  // Bug: Users can't use generated messages
  j10.main();

  // === COVERAGE TESTS ===
  // Bug: Specific option causes crash (edge cases)

  // All 40 occasions load wizard without crash
  occasions.main();

  // All 14 relationships can be selected
  relationships.main();

  // All 6 tones can be selected
  tones.main();
}
