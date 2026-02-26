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
│   └── apple-touch-icon.png      # iOS home screen icon
├── package.json                  # Node dependencies
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
│   ├── app.dart                  # Root MaterialApp, auth state listener
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
│   │   ├── occasion.dart         # Occasion enum with colors
│   │   ├── relationship.dart     # Relationship enum
│   │   ├── tone.dart             # Tone enum
│   │   ├── message_length.dart   # MessageLength enum
│   │   ├── generated_message.dart      # freezed model
│   │   ├── generated_message.freezed.dart
│   │   └── generated_message.g.dart
│   │
│   ├── providers/
│   │   └── providers.dart        # Riverpod providers
│   │
│   └── services/                 # Business logic
│       ├── ai_service.dart       # Gemini API integration
│       ├── auth_service.dart     # Auth orchestrator
│       ├── apple_auth_provider.dart
│       ├── google_auth_provider.dart
│       ├── supabase_auth_provider.dart
│       ├── biometric_service.dart
│       ├── subscription_service.dart  # RevenueCat
│       ├── usage_service.dart    # Free tier tracking (Supabase-backed)
│       ├── review_service.dart   # App Store review prompts
│       ├── log_service.dart      # Crashlytics logging
│       └── error_log_service.dart
│
├── features/                     # Feature modules
│   ├── auth/
│   │   ├── auth_screen.dart      # Sign in (Apple, Google, Email)
│   │   ├── email_auth_screen.dart
│   │   └── lock_screen.dart      # Biometric unlock
│   │
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/occasion_grid.dart
│   │
│   ├── generate/
│   │   ├── generate_screen.dart  # Multi-step wizard
│   │   └── widgets/
│   │
│   ├── results/
│   │   └── results_screen.dart
│   │
│   ├── paywall/
│   │   └── paywall_screen.dart   # RevenueCat paywall
│   │
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   │
│   └── settings/
│       ├── settings_screen.dart
│       ├── feedback_screen.dart
│       └── legal_screen.dart
│
└── shared/                       # Reusable UI (Atomic Design)
    ├── atoms/                    # Basic components
    ├── molecules/                # Compound components
    ├── organisms/                # Complex components
    └── theme/                    # Design tokens
        ├── app_colors.dart
        ├── app_spacing.dart
        ├── app_theme.dart
        └── app_typography.dart
```

### test/ - Unit & Widget Tests

```
test/
├── mocks/                        # Test doubles
│   ├── mock_ai_service.dart
│   ├── mock_auth_service.dart
│   ├── mock_biometric_service.dart
│   ├── mock_subscription_service.dart
│   └── mocks.dart                # Barrel export
├── models/                       # Model tests
├── services/                     # Service tests
├── theme/                        # Theme tests
└── widgets/screens/              # Widget tests
```

### integration_test/ - E2E Tests (Patrol)

```
integration_test/
├── app_test.dart                 # Mocked Patrol tests
└── device_only/                  # Real device only
    └── revenuecat_test.dart      # Real RevenueCat SDK tests
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
└── key.properties.example        # Signing config template
```

### Database

```
supabase/
└── migrations/
    ├── 001_create_user_usage.sql       # Usage tracking table
    └── 002_fix_function_security.sql   # Security fix
```

### Documentation

```
docs/
├── ARCHITECTURE.md               # This file
├── BACKLOG.md                    # Feature backlog
├── LAUNCH_CHECKLIST.md           # Release checklist
├── PRODUCT_SPEC.md               # Product requirements
├── SERVICE_ENDPOINTS.md          # SDK method coverage
├── STACK_TEMPLATE.md             # Tech stack blueprint
├── SUBSCRIPTION_TESTING.md       # RevenueCat manual testing
└── TEST_AUDIT.md                 # Test coverage details
```

### Assets

```
assets/
└── images/
    ├── logo.png                  # App logo (splash, about)
    └── icons/                    # Custom icons
```

### Config Files

```
pubspec.yaml                      # Flutter dependencies
pubspec.lock                      # Locked dependency versions
analysis_options.yaml             # Linter rules (strict mode)
firebase.json                     # Firebase project config
.gitignore                        # Git exclusions
.github/workflows/ci.yml          # GitHub Actions CI
CLAUDE.md                         # AI assistant context
README.md                         # Project overview
```

---

## Security

| Layer | Implementation |
|-------|----------------|
| **Transport** | HTTPS only (Android: network_security_config, iOS: ATS) |
| **Auth** | Supabase (bcrypt passwords, JWT sessions) |
| **Payments** | RevenueCat → App Store/Play Store (no card data) |
| **Code** | R8/ProGuard obfuscation, log stripping |

---

## Key Patterns

| Pattern | Location |
|---------|----------|
| Dependency Injection | `core/interfaces/` + `core/providers/` |
| Immutable Models | freezed in `core/models/` |
| Feature Modules | `features/{name}/` with screen + widgets |
| Atomic Design | `shared/atoms/`, `molecules/`, `organisms/` |
| Service Layer | `core/services/` implements `core/interfaces/` |
