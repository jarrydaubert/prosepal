# Prosepal Test Suite

> **Philosophy**: Every test must answer "What bug is this test trying to find?"

## Quick Reference

```bash
# Unit & Widget tests (427 tests, ~7 seconds)
flutter test

# Single test file
flutter test test/services/auth_service_test.dart

# Integration tests (requires device/simulator)
flutter test integration_test/e2e_test.dart -d <device-id>

# Just smoke tests (quick sanity check)
flutter test integration_test/smoke_test.dart -d <device-id>
```

## Test Pyramid

```
                    /\
                   /  \  Integration (~100 tests)
                  /    \  "User can't complete flow"
                 /------\
                /        \  Widget (~50 tests)
               /          \  "Screen doesn't render correctly"
              /------------\
             /              \  Unit (~377 tests)
            /________________\  "Logic is wrong"
```

## Structure

```
test/                              # Unit & Widget (no device needed)
├── services/                      # Service unit tests
│   ├── ai_service_generation_test.dart    # AI response parsing, errors
│   ├── auth_service_test.dart             # OAuth, session handling
│   ├── subscription_service_test.dart     # RevenueCat, entitlements
│   ├── usage_service_test.dart            # Generation counting
│   ├── biometric_service_test.dart        # Face ID / Touch ID
│   └── review_service_test.dart           # App Store review prompts
├── widgets/screens/               # Screen widget tests
│   ├── home_screen_test.dart              # Home renders, navigation
│   ├── settings_screen_test.dart          # Settings UI
│   ├── results_screen_test.dart           # Generated messages display
│   └── generate_screen_test.dart          # Wizard flow UI
├── models/                        # Model serialization tests
│   └── models_test.dart                   # JSON round-trip
├── errors/                        # Error handling tests
│   └── auth_errors_test.dart              # Error message mapping
├── app/                           # App lifecycle tests
│   └── app_lifecycle_test.dart            # Init, state changes
└── mocks/                         # Shared mock implementations
    ├── mocks.dart                         # Barrel export
    ├── mock_auth_service.dart
    ├── mock_subscription_service.dart
    ├── mock_ai_service.dart
    └── ...

integration_test/                  # Integration (device required)
├── smoke_test.dart                # Quick sanity (5 tests)
├── e2e_test.dart                  # Entry point for all tests
├── journeys/                      # User journey tests
│   ├── _helpers.dart                      # Shared test utilities
│   ├── j1_fresh_install_test.dart         # First-time user flow
│   ├── j2_upgrade_flow_test.dart          # Free → paid
│   ├── j3_pro_generate_test.dart          # Pro user experience
│   ├── j4_settings_test.dart              # Account management
│   ├── j5_navigation_test.dart            # Back button, state
│   ├── j6_error_resilience_test.dart      # Crash resistance
│   ├── j7_restore_flow_test.dart          # Restore purchases
│   ├── j8_paywall_test.dart               # Pricing display
│   ├── j9_wizard_details_test.dart        # Customization
│   └── j10_results_actions_test.dart      # Copy, share, regenerate
└── coverage/                      # All options work
    ├── occasions_test.dart                # All 41 occasions
    ├── relationships_test.dart            # All 14 relationships
    └── tones_test.dart                    # All 6 tones
```

## What Bug Does Each Test Find?

### Unit Tests
| Test File | Bug It Catches |
|-----------|----------------|
| `ai_service_generation_test.dart` | AI response parsing fails, wrong message count |
| `auth_service_test.dart` | OAuth token handling broken, cancellation not detected |
| `subscription_service_test.dart` | RevenueCat not initialized, entitlement check wrong |
| `usage_service_test.dart` | Free user count wrong, sync fails |
| `biometric_service_test.dart` | Biometric prompt crashes |

### Widget Tests
| Test File | Bug It Catches |
|-----------|----------------|
| `home_screen_test.dart` | Occasions don't render, PRO badge missing |
| `generate_screen_test.dart` | Wizard step broken, generate button missing |
| `settings_screen_test.dart` | Settings options not displayed |
| `results_screen_test.dart` | Messages don't display, copy button missing |

### Integration Tests (Journeys)
| Journey | Bug It Catches |
|---------|----------------|
| J1: Fresh Install | First-time user blocked from using app |
| J2: Upgrade Flow | Users can't pay (revenue loss!) |
| J3: Pro Generate | Paying customers can't use features |
| J4: Settings | Users can't manage account |
| J5: Navigation | Users get stuck, can't go back |
| J6: Error Resilience | App crashes under normal use |
| J7: Restore Flow | Users lose subscription after reinstall |
| J8: Paywall | Pricing not displayed |
| J9: Wizard Details | Customization broken |
| J10: Results Actions | Can't copy/share generated messages |

### Coverage Tests
| Test | Bug It Catches |
|------|----------------|
| `occasions_test.dart` | Specific occasion (e.g., Kwanzaa) crashes |
| `relationships_test.dart` | Specific relationship crashes wizard |
| `tones_test.dart` | Specific tone crashes generation |

## Mocks

Import all mocks:
```dart
import '../mocks/mocks.dart';
```

| Mock | Purpose |
|------|---------|
| `MockAuthService` | Supabase auth without real network |
| `MockSubscriptionService` | RevenueCat without real API |
| `MockAiService` | AI generation without real API calls |
| `MockBiometricService` | Biometric auth simulation |

## Firebase Test Lab

Build and run on FTL:

```bash
# Android
flutter build apk --debug -t integration_test/e2e_test.dart
cd android && ./gradlew app:assembleAndroidTest
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33 \
  --timeout 20m

# iOS
flutter build ios integration_test/e2e_test.dart --release
# Then upload to FTL via console or gcloud
```

## Pre-Launch Checklist

Manual verification on real device:
- [ ] Apple Sign In works
- [ ] Google Sign In works
- [ ] RevenueCat offerings load
- [ ] Test purchase unlocks Pro
- [ ] AI generates 3 messages
- [ ] Copy to clipboard works
- [ ] Share sheet opens
