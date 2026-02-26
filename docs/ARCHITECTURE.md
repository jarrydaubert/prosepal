# Prosepal Architecture

> Directory structure and file purposes. Evergreen reference - no metrics or versions.

```
Project Nexus/
├── prosepal/                     # Flutter mobile app (main codebase)
├── prosepal-web/                 # Vercel landing page (legal, support)
│
└── [See detailed structures below]


================================================================================
prosepal-web/ (Landing Page)
================================================================================

prosepal-web/
├── public/
│   ├── index.html                # Landing page
│   ├── privacy.html              # Privacy policy
│   ├── terms.html                # Terms of service
│   ├── support.html              # Support/contact page
│   ├── logo.png                  # App logo
│   ├── favicon.png               # Browser favicon
│   └── apple-touch-icon.png      # iOS home screen icon
│
├── package.json                  # Node dependencies (minimal)
├── package-lock.json             # Locked versions
├── vercel.json                   # Vercel deployment config
└── .vercel/                      # Vercel project metadata


================================================================================
prosepal/ (Flutter App)
================================================================================

prosepal/
├── lib/                          # Application source code
│   ├── main.dart                 # App entry point, Firebase init, error handling
│   ├── firebase_options.dart     # Firebase config (auto-generated)
│   │
│   ├── app/
│   │   ├── app.dart              # Root MaterialApp widget, theme setup
│   │   └── router.dart           # GoRouter config, route definitions, guards
│   │
│   ├── core/
│   │   ├── errors/
│   │   │   └── auth_errors.dart  # AuthErrorHandler - user-friendly error messages
│   │   │
│   │   ├── interfaces/
│   │   │   ├── interfaces.dart       # Barrel export
│   │   │   ├── auth_interface.dart   # IAuthService contract
│   │   │   ├── biometric_interface.dart  # IBiometricService contract
│   │   │   └── subscription_interface.dart  # ISubscriptionService contract
│   │   │
│   │   ├── models/
│   │   │   ├── models.dart           # Barrel export
│   │   │   ├── occasion.dart         # Occasion enum (Birthday, Wedding, etc.)
│   │   │   ├── relationship.dart     # Relationship enum (Friend, Parent, etc.)
│   │   │   ├── tone.dart             # Tone enum (Heartfelt, Funny, etc.)
│   │   │   ├── message_length.dart   # MessageLength enum (Brief, Standard, etc.)
│   │   │   └── generated_message.dart  # GeneratedMessage data class
│   │   │
│   │   ├── providers/
│   │   │   └── providers.dart    # Riverpod providers for all services
│   │   │
│   │   └── services/
│   │       ├── services.dart         # Barrel export
│   │       ├── ai_service.dart       # Firebase AI / Gemini message generation
│   │       ├── auth_service.dart     # Apple, Google, Email auth via Supabase
│   │       ├── biometric_service.dart  # Face ID / Touch ID for app lock
│   │       ├── subscription_service.dart  # RevenueCat subscriptions
│   │       ├── usage_service.dart    # Free tier usage tracking
│   │       ├── review_service.dart   # App Store review prompts
│   │       └── error_log_service.dart  # Crashlytics error logging
│   │
│   ├── features/                 # Feature modules (screens + widgets)
│   │   ├── auth/
│   │   │   ├── auth_screen.dart      # Sign in screen (Apple, Google, Email buttons)
│   │   │   ├── email_auth_screen.dart  # Magic link email entry
│   │   │   └── lock_screen.dart      # Biometric unlock screen
│   │   │
│   │   ├── home/
│   │   │   ├── home_screen.dart      # Main screen with occasion grid
│   │   │   └── widgets/
│   │   │       └── occasion_grid.dart  # Grid of occasion cards
│   │   │
│   │   ├── generate/
│   │   │   ├── generate_screen.dart  # Multi-step message generation wizard
│   │   │   └── widgets/
│   │   │       ├── relationship_picker.dart  # Step 1: Who is this for?
│   │   │       ├── tone_selector.dart       # Step 2: What tone?
│   │   │       └── details_input.dart       # Step 3: Name, details, length
│   │   │
│   │   ├── results/
│   │   │   └── results_screen.dart   # Generated messages display, copy, regenerate
│   │   │
│   │   ├── paywall/
│   │   │   └── paywall_screen.dart   # RevenueCat paywall wrapper
│   │   │
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart  # First-launch tutorial
│   │   │
│   │   └── settings/
│   │       ├── settings_screen.dart  # Account, preferences, legal links
│   │       ├── feedback_screen.dart  # In-app feedback form
│   │       └── legal_screen.dart     # Privacy, Terms webview
│   │
│   └── shared/                   # Reusable UI components (Atomic Design)
│       ├── atoms/                # Smallest components
│       │   ├── atoms.dart            # Barrel export
│       │   ├── app_button.dart       # Styled button variants
│       │   ├── app_card.dart         # Styled card container
│       │   └── app_icon.dart         # Icon with consistent sizing
│       │
│       ├── molecules/            # Combinations of atoms
│       │   ├── molecules.dart        # Barrel export
│       │   ├── loading_indicator.dart  # Spinner with optional message
│       │   ├── generation_loading_overlay.dart  # Full-screen generation state
│       │   ├── section_header.dart   # Title + optional action
│       │   ├── selection_chip.dart   # Selectable pill/chip
│       │   ├── settings_tile.dart    # Settings row item
│       │   └── usage_indicator.dart  # Free tier remaining count
│       │
│       ├── organisms/            # Complex components
│       │   ├── organisms.dart        # Barrel export
│       │   ├── message_card.dart     # Generated message with copy button
│       │   ├── occasion_tile.dart    # Occasion card for home grid
│       │   └── paywall_card.dart     # Subscription offer card
│       │
│       └── theme/                # Design tokens
│           ├── app_colors.dart       # Color palette
│           ├── app_spacing.dart      # Spacing constants
│           ├── app_theme.dart        # ThemeData configuration
│           └── app_typography.dart   # Text styles
│
├── test/                         # Unit and widget tests
│   ├── widget_test.dart          # Basic smoke test
│   │
│   ├── mocks/
│   │   ├── mocks.dart                # Barrel export
│   │   ├── mock_auth_service.dart    # IAuthService mock with call tracking
│   │   ├── mock_auth_service_test.dart  # Tests for the mock itself
│   │   ├── mock_biometric_service.dart  # IBiometricService mock
│   │   ├── mock_biometric_service_test.dart
│   │   ├── mock_subscription_service.dart  # ISubscriptionService mock
│   │   └── mock_subscription_service_test.dart
│   │
│   ├── app/
│   │   └── app_lifecycle_test.dart   # App state lifecycle tests
│   │
│   ├── errors/
│   │   └── auth_errors_test.dart     # AuthErrorHandler message mapping
│   │
│   ├── models/
│   │   ├── models_test.dart          # Cross-model tests
│   │   ├── occasion_test.dart        # Occasion enum tests
│   │   ├── relationship_test.dart    # Relationship enum tests
│   │   ├── tone_test.dart            # Tone enum tests
│   │   └── message_length_test.dart  # MessageLength enum tests
│   │
│   ├── services/
│   │   ├── ai_service_test.dart          # AI service unit tests
│   │   ├── ai_service_http_test.dart     # AI HTTP/retry logic tests
│   │   ├── ai_service_generation_test.dart  # Generation flow tests
│   │   ├── auth_service_with_mock_test.dart  # Auth via mock tests
│   │   ├── auth_service_crypto_test.dart     # Nonce/SHA256 tests
│   │   ├── auth_service_compliance_test.dart # URL/contract tests
│   │   ├── biometric_service_mock_test.dart  # Biometric tests
│   │   ├── subscription_service_with_mock_test.dart  # Subscription tests
│   │   ├── usage_service_test.dart       # Usage tracking tests
│   │   ├── review_service_test.dart      # Review prompt tests
│   │   └── error_log_service_test.dart   # Error logging tests
│   │
│   ├── theme/
│   │   ├── app_colors_test.dart      # Color constant tests
│   │   └── app_spacing_test.dart     # Spacing constant tests
│   │
│   └── widgets/
│       └── screens/
│           ├── home_screen_test.dart     # Home screen widget tests
│           └── generate_screen_test.dart # Generate wizard widget tests
│
├── integration_test/             # E2E integration tests
│   ├── app_test.dart             # Full app flow tests
│   ├── auth_test.dart            # Auth flow integration tests
│   ├── revenuecat_test.dart      # Subscription flow tests
│   └── firebase_test.dart        # Firebase integration tests
│
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # This file - directory structure
│   ├── BACKLOG.md                # Feature backlog and priorities
│   ├── PRODUCT_SPEC.md           # Product requirements
│   ├── SERVICE_ENDPOINTS.md      # SDK methods and test coverage
│   ├── STACK_TEMPLATE.md         # Technology stack reference
│   ├── TEST_AUDIT.md             # Test coverage audit
│   └── ASO_METADATA.md           # App Store metadata
│
├── assets/
│   └── images/                   # App images (logo, icons)
│
├── ios/                          # iOS platform code
│   ├── Runner/                   # Xcode project
│   ├── Podfile                   # CocoaPods dependencies
│   └── Runner.xcworkspace/       # Xcode workspace
│
├── android/                      # Android platform code
│   ├── app/                      # Android app module
│   └── build.gradle.kts          # Gradle build config
│
├── pubspec.yaml                  # Flutter dependencies
├── analysis_options.yaml         # Dart analyzer + lint rules
├── firebase.json                 # Firebase project config
└── CLAUDE.md                     # AI assistant context
```

## Key Patterns

### Dependency Injection
- Services defined as interfaces in `core/interfaces/`
- Implementations in `core/services/`
- Provided via Riverpod in `core/providers/providers.dart`
- Tests inject mocks from `test/mocks/`

### Feature Organization
- Each feature has its own folder under `features/`
- Screen is the main file, widgets subfolder for components
- Features only import from `core/` and `shared/`

### Atomic Design (shared/)
- **Atoms**: Single-purpose, no business logic
- **Molecules**: Combine atoms, minimal logic
- **Organisms**: Complex components, may have state

### Test Organization
- Mirror `lib/` structure in `test/`
- Mocks are self-tested (`*_test.dart` for mocks)
- Integration tests in separate `integration_test/` folder
