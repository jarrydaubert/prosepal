# Prosepal Architecture

> Directory structure and file purposes. Evergreen reference - no metrics or versions.

---

## Project Structure

```
Project Nexus/
├── prosepal/                     # Flutter mobile app
└── prosepal-web/                 # Vercel landing page
```

---

## prosepal-web/ (Landing Page)

```
prosepal-web/
├── public/
│   ├── index.html                # Landing page with App Store/Play Store badges
│   ├── privacy.html              # Privacy policy
│   ├── terms.html                # Terms of service
│   ├── support.html              # Support/contact page
│   ├── logo.png                  # App logo
│   ├── favicon.png               # Browser favicon
│   ├── apple-touch-icon.png      # iOS home screen icon
│   ├── llms.txt                  # LLM context file
│   ├── sitemap.xml               # Search engine sitemap
│   └── robots.txt                # Search engine crawl rules
├── package.json                  # Node dependencies (serve)
├── vercel.json                   # Vercel deployment config
└── .vercel/                      # Vercel project metadata
```

---

## prosepal/ (Flutter App)

### lib/ - Application Source

```
lib/
├── main.dart                     # Entry point, Firebase/Supabase init
├── firebase_options.dart         # Firebase config (auto-generated)
│
├── app/
│   ├── app.dart                  # Root MaterialApp, auth state listener, lock timeout
│   └── router.dart               # GoRouter config, route guards
│
├── core/
│   ├── config/
│   │   └── ai_config.dart        # AI model parameters (model name, tokens, etc.)
│   │
│   ├── errors/
│   │   └── auth_errors.dart      # User-friendly error message mapping
│   │
│   ├── interfaces/               # Service contracts (for DI/testing)
│   │   ├── auth_interface.dart
│   │   ├── biometric_interface.dart
│   │   ├── subscription_interface.dart
│   │   ├── apple_auth_provider.dart
│   │   ├── google_auth_provider.dart
│   │   └── supabase_auth_provider.dart
│   │
│   ├── models/                   # Data models
│   │   ├── models.dart           # Barrel export
│   │   ├── occasion.dart         # Occasion enum with colors (45 occasions)
│   │   ├── relationship.dart     # Relationship enum
│   │   ├── tone.dart             # Tone enum
│   │   ├── message_length.dart   # MessageLength enum
│   │   ├── generated_message.dart      # Freezed model
│   │   ├── generated_message.freezed.dart
│   │   └── generated_message.g.dart
│   │
│   ├── providers/
│   │   └── providers.dart        # Riverpod providers (state management)
│   │
│   └── services/                 # Business logic
│       ├── ai_service.dart       # Firebase AI (Gemini) integration
│       ├── auth_service.dart     # Auth orchestrator
│       ├── auth_throttle_service.dart  # Auth rate limiting
│       ├── apple_auth_provider.dart
│       ├── google_auth_provider.dart
│       ├── supabase_auth_provider.dart
│       ├── biometric_service.dart      # Face ID / Touch ID / Fingerprint
│       ├── subscription_service.dart   # RevenueCat integration
│       ├── usage_service.dart          # Free/Pro usage tracking (Supabase)
│       ├── history_service.dart        # Message history (Supabase)
│       ├── rate_limit_service.dart     # API rate limiting (Supabase)
│       ├── device_fingerprint_service.dart  # Device ID tracking
│       ├── reauth_service.dart         # Re-authentication for sensitive ops
│       ├── review_service.dart         # App Store review prompts
│       ├── diagnostic_service.dart     # Debug diagnostics collection
│       ├── log_service.dart            # Crashlytics logging
│       └── error_log_service.dart      # Error log persistence
│
├── features/                     # Feature modules
│   ├── auth/
│   │   ├── auth_screen.dart      # Sign in (Apple, Google, Email)
│   │   ├── email_auth_screen.dart
│   │   └── lock_screen.dart      # Biometric unlock
│   │
│   ├── home/
│   │   ├── home_screen.dart      # Occasion grid
│   │   └── widgets/
│   │       └── occasion_grid.dart
│   │
│   ├── generate/
│   │   ├── generate_screen.dart  # Multi-step wizard
│   │   └── widgets/
│   │       ├── relationship_picker.dart
│   │       ├── tone_selector.dart
│   │       └── details_input.dart
│   │
│   ├── results/
│   │   └── results_screen.dart   # Generated messages display
│   │
│   ├── history/
│   │   └── history_screen.dart   # Past generations
│   │
│   ├── paywall/
│   │   └── custom_paywall_screen.dart  # RevenueCat paywall
│   │
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   └── biometric_setup_screen.dart
│   │
│   └── settings/
│       ├── settings_screen.dart
│       └── feedback_screen.dart  # Support with diagnostic logs
│
└── shared/                       # Reusable UI (Atomic Design)
    ├── atoms/                    # Basic components
    │   ├── app_button.dart
    │   └── tappable_card.dart
    │
    ├── molecules/                # Compound components
    │   ├── copy_button.dart      # Copy with checkmark feedback
    │   ├── usage_indicator.dart  # Free/Pro usage display
    │   └── generation_loading_overlay.dart
    │
    ├── organisms/                # Complex components
    │   ├── generating_overlay.dart  # Full-screen loading animation
    │   └── message_card.dart
    │
    └── theme/                    # Design tokens
        ├── app_colors.dart       # Brand colors, semantic colors
        ├── app_spacing.dart      # 8px grid system
        ├── app_theme.dart        # MaterialApp theme
        └── app_typography.dart   # Nunito font scale
```

### test/ - Unit & Widget Tests

```
test/
├── README.md                     # Test documentation
├── mocks/                        # Test doubles
│   ├── mocks.dart                # Barrel export
│   ├── mock_ai_service.dart
│   ├── mock_auth_service.dart
│   ├── mock_biometric_service.dart
│   ├── mock_subscription_service.dart
│   ├── mock_usage_service.dart
│   ├── mock_history_service.dart
│   ├── mock_rate_limit_service.dart
│   ├── mock_device_fingerprint_service.dart
│   └── mock_review_service.dart
├── app/
│   └── app_lifecycle_test.dart
├── errors/
│   └── auth_errors_test.dart
├── models/
│   ├── models_test.dart
│   └── enum_validation_test.dart
├── services/
│   ├── ai_service_test.dart
│   ├── auth_service_test.dart
│   ├── auth_throttle_service_test.dart
│   ├── biometric_service_test.dart
│   ├── device_fingerprint_service_test.dart
│   ├── history_service_test.dart
│   ├── rate_limit_service_test.dart
│   ├── review_service_test.dart
│   ├── subscription_service_test.dart
│   └── usage_service_test.dart
└── widgets/
    ├── screens/
    │   ├── generate_screen_test.dart
    │   ├── home_screen_test.dart
    │   ├── results_screen_test.dart
    │   └── settings_screen_test.dart
    └── shared/
        └── selection_chip_test.dart
```

### integration_test/ - E2E Tests (Patrol)

```
integration_test/
├── app_test.dart                 # Main test runner
├── journeys/                     # User journey tests
│   ├── _helpers.dart             # Shared test utilities
│   ├── j1_fresh_install_test.dart
│   ├── j2_upgrade_flow_test.dart
│   ├── j3_pro_generate_test.dart
│   ├── j4_settings_test.dart
│   ├── j5_navigation_test.dart
│   ├── j6_error_resilience_test.dart
│   ├── j7_restore_flow_test.dart
│   ├── j8_paywall_test.dart
│   ├── j9_wizard_details_test.dart
│   └── j10_results_actions_test.dart
└── coverage/                     # Coverage tests
    ├── occasions_test.dart
    ├── relationships_test.dart
    └── tones_test.dart
```

### Platform Code

```
ios/
├── Runner/
│   ├── Info.plist                # Permissions, URL schemes, ATS
│   └── AppDelegate.swift
├── Podfile                       # iOS 15.0 minimum
└── Runner.xcworkspace/

android/
├── app/
│   ├── build.gradle.kts          # SDK versions, signing, R8/ProGuard
│   ├── proguard-rules.pro        # Obfuscation rules
│   ├── google-services.json      # Firebase config
│   └── src/main/
│       ├── AndroidManifest.xml   # Permissions, orientation
│       └── res/xml/
│           └── network_security_config.xml  # Block cleartext traffic
├── key.properties.example        # Signing config template
└── key.properties                # Actual signing config (gitignored)
```

### Database (Supabase)

```
supabase/
└── functions/
    └── index.ts                  # Edge functions (delete-user, etc.)
```

### Documentation

```
docs/
├── ARCHITECTURE.md               # This file
├── BACKLOG.md                    # Feature backlog & priorities
├── PRODUCT_SPEC.md               # Product requirements
├── LAUNCH_CHECKLIST.md           # Release checklist
├── APP_STORE_SUBMISSION_GUIDE.md # App Store submission guide
├── SERVICE_ENDPOINTS.md          # SDK method coverage
├── STACK_TEMPLATE.md             # Tech stack blueprint
├── SUBSCRIPTION_TESTING.md       # RevenueCat manual testing
├── TESTING.md                    # Test strategy
├── USER_JOURNEYS.md              # User flow documentation
├── CLONING_PLAYBOOK.md           # How to clone for new apps
├── EXPANSION_STRATEGY.md         # Growth plans
├── PORTFOLIO_STRATEGY.md         # Multi-app strategy
└── MARKETING.md                  # Marketing content & ASO
```

### Assets

```
assets/
└── images/
    ├── logo.png                  # App logo (splash, about)
    └── icons/
        ├── google_g.png          # Google sign-in button
        ├── google_g@2x.png
        └── google_g@3x.png
```

### Scripts

```
scripts/
└── build_release.local.sh        # Local release build script
```

### Config Files

```
pubspec.yaml                      # Flutter dependencies
pubspec.lock                      # Locked dependency versions
analysis_options.yaml             # Linter rules (strict-casts, strict-raw-types)
firebase.json                     # Firebase project config
.gitignore                        # Git exclusions
.github/workflows/ci.yml          # GitHub Actions CI
CLAUDE.md                         # AI assistant context
```

---

## Security

| Layer | Implementation |
|-------|----------------|
| **Transport** | HTTPS only (Android: network_security_config, iOS: ATS) |
| **Auth** | Supabase (bcrypt passwords, JWT sessions) |
| **Biometric** | Local Auth (Face ID / Touch ID / Fingerprint) |
| **Payments** | RevenueCat → App Store/Play Store (no card data) |
| **Code** | R8/ProGuard obfuscation, log stripping |
| **Rate Limiting** | Supabase RPC functions |
| **Device Tracking** | Fingerprint service for abuse prevention |

---

## Key Patterns

| Pattern | Location |
|---------|----------|
| Dependency Injection | `core/interfaces/` + `core/providers/` |
| Immutable Models | Freezed in `core/models/` |
| Feature Modules | `features/{name}/` with screen + widgets |
| Atomic Design | `shared/atoms/`, `molecules/`, `organisms/` |
| Service Layer | `core/services/` implements `core/interfaces/` |
| State Management | Riverpod providers in `core/providers/` |

---

## Data Flow

```
User Action
    ↓
Feature Screen (UI)
    ↓
Riverpod Provider (State)
    ↓
Service (Business Logic)
    ↓
External API (Firebase AI, Supabase, RevenueCat)
```

---

## Test Coverage

| Layer | Test Type | Location |
|-------|-----------|----------|
| Models | Unit | `test/models/` |
| Services | Unit | `test/services/` |
| Widgets | Widget | `test/widgets/` |
| User Journeys | Integration | `integration_test/journeys/` |
| Enum Coverage | Integration | `integration_test/coverage/` |
