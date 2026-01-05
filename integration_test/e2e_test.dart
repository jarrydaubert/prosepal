/// E2E Integration Tests for Prosepal (Firebase Test Lab)
/// 
/// Single entry point that runs all user journey tests.
/// Designed for Firebase Test Lab with screenshots at key steps.
/// 
/// Build & Run:
///   # Android
///   cd android && ./gradlew app:assembleDebug -Ptarget="../integration_test/e2e_test.dart"
///   ./gradlew app:assembleAndroidTest
///   gcloud firebase test android run --type instrumentation \
///     --app build/app/outputs/apk/debug/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33 --timeout 20m
/// 
/// Test Structure:
///   journeys/
///     j1_fresh_install_test.dart    - Fresh install → Free generation
///     j2_upgrade_flow_test.dart     - Upgrade → Auth → Purchase
///     j3_pro_generate_test.dart     - Pro user → Generate → Sign out
///     j4_settings_test.dart         - Settings, biometrics, account
///     j5_navigation_test.dart       - Back button, wizard state
///     j6_error_resilience_test.dart - Rapid taps, errors, recovery
///     j7_restore_flow_test.dart     - Reinstall, restore purchases
///   coverage/
///     occasions_test.dart           - All 41 occasions
///     relationships_test.dart       - All 14 relationships
///     tones_test.dart               - All 6 tones
library;

// Journey tests
import 'journeys/j1_fresh_install_test.dart' as j1;
import 'journeys/j2_upgrade_flow_test.dart' as j2;
import 'journeys/j3_pro_generate_test.dart' as j3;
import 'journeys/j4_settings_test.dart' as j4;
import 'journeys/j5_navigation_test.dart' as j5;
import 'journeys/j6_error_resilience_test.dart' as j6;
import 'journeys/j7_restore_flow_test.dart' as j7;

// Coverage tests
import 'coverage/occasions_test.dart' as occasions;
import 'coverage/relationships_test.dart' as relationships;
import 'coverage/tones_test.dart' as tones;

void main() {
  // User journeys (critical paths)
  j1.main(); // Fresh Install → Free Generation
  j2.main(); // Upgrade Flow
  j3.main(); // Pro User Flow
  j4.main(); // Settings & Account
  j5.main(); // Navigation
  j6.main(); // Error Resilience
  j7.main(); // Restore Flow

  // Coverage tests (all options work)
  occasions.main();
  relationships.main();
  tones.main();
}
