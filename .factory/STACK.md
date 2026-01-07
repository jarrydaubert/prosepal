# Prosepal Project Stack Reference

> **Last Updated**: 2026-01-06
> **Droid reads this file at session start for context**

## Overview
- **App**: Prosepal - AI-powered greeting card message generator
- **Platform**: Flutter (iOS + Android)
- **Flutter**: 3.38.5 | **Dart**: 3.10.4

---

## CLI Tools & Versions

| Tool | Version | Path | Purpose |
|------|---------|------|---------|
| `flutter` | 3.38.5 | System | Build, test, run Flutter apps |
| `dart` | 3.10.4 | System | Dart SDK |
| `gcloud` | 550.0.0 | System | Firebase Test Lab, GCS, APIs |
| `gsutil` | 5.35 | System | Google Cloud Storage |
| `supabase` | 2.67.1 | `/opt/homebrew/bin/supabase` | Database, migrations, SQL |
| `gh` | 2.83.2 | System | GitHub CLI for PRs, issues |
| `node` | 24.11.1 | System | Node.js runtime |
| `npm` | 11.6.2 | System | Package manager |
| `pod` | 1.16.2 | System | CocoaPods for iOS |
| `xcodebuild` | Xcode 26.2 | System | iOS builds |
| `java` | 17.0.17 | `/Library/Java/JavaVirtualMachines/temurin-17.jdk` | Android builds |

---

## Backend Services & SDKs

### Supabase (Auth & Database)
- **SDK**: `supabase_flutter: ^2.12.0`
- **Project Ref**: `mwoxtqxzunsjmbdqezif`
- **Region**: Central EU (Frankfurt)
- **URL**: `https://mwoxtqxzunsjmbdqezif.supabase.co`
- **Dashboard**: `https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif`
- **Tables**: `user_usage`, `auth.users`
- **Features**: Auth (Email, Apple, Google), Usage tracking, Edge functions
- **Edge Functions**:
  - `delete-user`: `https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/delete-user`

### Firebase (AI & Analytics)
- **SDKs**:
  - `firebase_core: ^4.3.0`
  - `firebase_ai: ^3.6.1` (Gemini)
  - `firebase_analytics: ^12.1.0`
  - `firebase_crashlytics: ^5.0.6`
  - `firebase_app_check: ^0.4.1+3`
- **Project**: `prosepal-1a24b`
- **Console**: `https://console.firebase.google.com/project/prosepal-1a24b`
- **Test Lab GCS**: `gs://test-lab-7afd9c43jh0n4-kz51jc12z9kru/`

### RevenueCat (Payments)
- **SDK**: `purchases_flutter: ^9.10.2`, `purchases_ui_flutter: ^9.10.2`
- **Dashboard**: RevenueCat dashboard
- **Entitlement**: `pro`
- **Tiers**: Weekly ($2.99), Monthly ($4.99), Yearly ($29.99)

---

## All Flutter Dependencies

### Core
```yaml
flutter_riverpod: ^3.1.0      # State management
riverpod_annotation: ^4.0.0   # Riverpod codegen
go_router: ^17.0.1            # Navigation
```

### Backend SDKs
```yaml
supabase_flutter: ^2.12.0     # Auth & database (latest)
firebase_core: ^4.3.0         # Firebase base
firebase_ai: ^3.6.1           # Gemini AI (latest)
firebase_analytics: ^12.1.0   # Analytics
firebase_crashlytics: ^5.0.6  # Crash reporting
firebase_app_check: ^0.4.1+3  # App attestation
purchases_flutter: ^9.10.3    # RevenueCat (updated 2026-01-06)
purchases_ui_flutter: ^9.10.3 # RevenueCat UI (updated 2026-01-06)
```

### Auth
```yaml
google_sign_in: ^7.2.0        # Google OAuth
sign_in_with_apple: ^7.0.1    # Apple OAuth
local_auth: ^3.0.0            # Biometrics
crypto: ^3.0.7                # Nonce generation
```

### UI
```yaml
google_fonts: ^6.2.1          # Typography
flutter_animate: ^4.5.2       # Animations
flutter_native_splash: ^2.4.7 # Native splash
gap: ^3.0.1                   # Spacing widget
shimmer: ^3.0.0               # Loading effects
confetti: ^0.8.0              # Celebrations
rive: ^0.14.0                 # Rive animations
```

### Utils
```yaml
shared_preferences: ^2.5.3    # Local storage
uuid: ^4.5.1                  # UUID generation
intl: ^0.20.2                 # Internationalization
url_launcher: ^6.3.1          # Open URLs
share_plus: ^12.0.1           # Share sheet
package_info_plus: ^9.0.0     # App version
device_info_plus: ^12.3.0     # Device info (updated 2026-01-06)
in_app_review: ^2.0.11        # App Store reviews
freezed_annotation: ^3.1.0    # Immutable models
json_annotation: ^4.9.0       # JSON serialization
```

---

## Deployment & Hosting

### Vercel (Web)
- **Project**: `prosepal-web` (sibling directory)
- **CLI**: `npx vercel` or `vercel`
- **Features**: Edge functions, Analytics

### App Store Connect (iOS)
- **Bundle ID**: `com.prosepal.prosepal`
- **Test User**: `appreview@prosepal.app` / `ProsepalReview2025!`
- **Status**: v1.0 Ready to Submit

### Google Play Console (Android)
- **Package**: `com.prosepal.prosepal`
- **Status**: Not yet submitted

---

## Common CLI Commands

### Flutter
```bash
# Run app
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test.dart

# Coverage
flutter test --coverage

# Analyze
flutter analyze

# Clean
flutter clean && flutter pub get

# Update packages
flutter pub upgrade

# Generate code (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs
```

### Firebase Test Lab
```bash
# Build for FTL (requires Java 17)
JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
  flutter build apk --debug -t integration_test/e2e_test.dart

# Build test APK
cd android && ./gradlew app:assembleDebugAndroidTest && cd ..

# Run on FTL
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33 \
  --timeout 15m

# List available devices
gcloud firebase test android models list

# Check GCS results
gsutil ls gs://test-lab-7afd9c43jh0n4-kz51jc12z9kru/
```

### Supabase
```bash
# Link project
supabase link --project-ref mwoxtqxzunsjmbdqezif

# List projects
supabase projects list

# Generate types (requires Docker)
supabase gen types typescript --linked > lib/types/supabase.ts

# Database migrations (requires Docker)
supabase db push
supabase db pull

# NOTE: Many supabase CLI commands require Docker running
# For SQL queries, use Supabase Dashboard SQL Editor instead
```

### GitHub
```bash
# Create PR
gh pr create --title "Title" --body "Description"

# List PRs
gh pr list

# Check out PR
gh pr checkout <number>

# Create issue
gh issue create --title "Title" --body "Description"
```

### Native Splash
```bash
# Generate splash screens
dart run flutter_native_splash:create

# Remove splash screens
dart run flutter_native_splash:remove
```

### iOS Specific
```bash
# Install pods
cd ios && pod install && cd ..

# Update pods
cd ios && pod update && cd ..

# Clean iOS build
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### Vercel (Web)
```bash
# Deploy preview
npx vercel

# Deploy production
npx vercel --prod

# List deployments
npx vercel ls
```

---

## Testing Infrastructure

### Unit Tests
- **Location**: `test/`
- **Count**: 458 tests
- **Coverage**: ~65%
- **Command**: `flutter test`

### Integration Tests (Firebase Test Lab)
- **Location**: `integration_test/`
- **Count**: 91 tests
- **APK Path**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Test APK**: `build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- **Build Requires**: Java 17 (`JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`)

### FTL Command
```bash
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33 \
  --timeout 15m
```

---

## Key Files & Directories

```
lib/
├── main.dart                    # App entry, SDK initialization
├── app/
│   ├── app.dart                 # MaterialApp wrapper
│   └── router.dart              # GoRouter navigation
├── core/
│   ├── services/                # Backend integrations
│   │   ├── auth_service.dart    # Supabase auth
│   │   ├── usage_service.dart   # Usage tracking (Supabase + local)
│   │   ├── subscription_service.dart  # RevenueCat
│   │   └── ai_service.dart      # Firebase AI (Gemini)
│   └── providers/               # Riverpod providers
├── features/
│   ├── onboarding/              # Onboarding carousel
│   ├── home/                    # Occasion grid
│   ├── generate/                # Message generation wizard
│   ├── results/                 # Generated messages display
│   ├── paywall/                 # Custom paywall UI
│   ├── auth/                    # Sign in screens
│   └── settings/                # App settings
└── shared/                      # Reusable components
```

---

## Environment Notes

- **macOS**: darwin 25.2.0
- **Java 17 Required**: For Android builds
- **Docker**: Required for `supabase db` commands (not always running)
- **No ripgrep**: Use Droid's Grep tool instead

---

## Common Tasks

### Reset Test User Usage
```sql
-- Run in Supabase SQL Editor
DELETE FROM public.user_usage 
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'appreview@prosepal.app'
);
```

### Build for FTL
```bash
JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
  flutter build apk --debug -t integration_test/e2e_test.dart
```

### Generate Native Splash
```bash
dart run flutter_native_splash:create
```

---

## Pricing Structure

| Tier | Price | Per Week | Free Trial |
|------|-------|----------|------------|
| Weekly | $2.99/wk | $2.99 | 3 days |
| Monthly | $4.99/mo | ~$1.15 | 1 week |
| Yearly | $29.99/yr | ~$0.58 | 1 week |

- **Free Tier**: 1 lifetime generation
- **Pro Tier**: 500 generations/month
