# Prosepal Architecture Overview

---
**Document Control**

| Field | Value |
|-------|-------|
| Version | 1.1.0 |
| Classification | Internal |
| Owner | Development Team |
| Last Reviewed | 2026-01-17 |
| Next Review | 2026-07-17 |

---

## Scope

This document covers the technical architecture of the Prosepal mobile application:

**In Scope:**
- Flutter application architecture and patterns
- State management and dependency injection
- Authentication and authorization flows
- AI generation pipeline
- Subscription and monetization
- Data persistence and configuration

**Out of Scope:**
- prosepal-web marketing site (separate codebase)
- Infrastructure/DevOps (Firebase, Supabase consoles)
- Security controls (see `SECURITY.md`)

---

## Executive Summary

Prosepal is a production-grade Flutter application for AI-powered greeting card message generation. Built on a shared tech stack designed for portfolio replication, it implements clean architecture principles with interface-based dependency injection, multi-provider authentication, subscription monetization, and reactive state management.

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Framework | Flutter 3.38+ / Dart 3.10+ | Cross-platform mobile |
| State | Riverpod 3.x | Reactive state management |
| Navigation | GoRouter | Declarative routing with guards |
| AI | Firebase AI (Gemini 3 Flash) | Message generation |
| Auth | Supabase | Multi-provider authentication |
| Database | Supabase PostgreSQL | User data, usage tracking |
| Payments | RevenueCat | Subscription management |
| Analytics | Firebase Analytics | User behavior tracking |
| Crash Reporting | Firebase Crashlytics | Error monitoring |
| Feature Flags | Firebase Remote Config | Runtime configuration |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  features/ (9 modules)                                      │ │
│  │  ├── auth/          Sign-in screens                        │ │
│  │  ├── home/          Occasion grid (40 occasions)           │ │
│  │  ├── generate/      Multi-step wizard                      │ │
│  │  ├── results/       Generated messages                     │ │
│  │  ├── history/       Past generations                       │ │
│  │  ├── paywall/       Subscription UI                        │ │
│  │  ├── settings/      Account management                     │ │
│  │  ├── onboarding/    User education                         │ │
│  │  └── error/         Error screens                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  shared/                                                    │ │
│  │  ├── components/    Reusable widgets                       │ │
│  │  └── theme/         Design tokens, colors, typography      │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   STATE LAYER     │
                    │  core/providers/  │
                    │  (Riverpod 3.x)   │
                    └─────────┬─────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                     BUSINESS LOGIC LAYER                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  core/services/ (20 files)                                  │ │
│  │  ├── ai_service.dart           Gemini generation           │ │
│  │  ├── auth_service.dart         Multi-provider auth         │ │
│  │  ├── subscription_service.dart RevenueCat integration      │ │
│  │  ├── usage_service.dart        Tier tracking               │ │
│  │  ├── history_service.dart      Message storage             │ │
│  │  ├── biometric_service.dart    Face ID/Touch ID            │ │
│  │  ├── rate_limit_service.dart   API abuse prevention        │ │
│  │  ├── remote_config_service.dart Feature flags              │ │
│  │  └── log_service.dart          Crashlytics integration     │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  core/interfaces/                                           │ │
│  │  ├── IAuthService              Auth contract               │ │
│  │  ├── ISubscriptionService      Payment contract            │ │
│  │  ├── IAppleAuthProvider        Apple OAuth contract        │ │
│  │  ├── IGoogleAuthProvider       Google OAuth contract       │ │
│  │  └── ISupabaseAuthProvider     Backend contract            │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                         DATA LAYER                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  core/models/ (Freezed immutable models)                    │ │
│  │  ├── GeneratedMessage, GenerationResult                    │ │
│  │  ├── Occasion (40 values), Relationship, Tone              │ │
│  │  └── MessageLength                                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  core/config/                                               │ │
│  │  ├── app_config.dart           Environment variables       │ │
│  │  ├── ai_config.dart            Model parameters            │ │
│  │  └── preference_keys.dart      Storage key constants       │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                      EXTERNAL SERVICES                          │
│                                                                 │
│   Firebase           Supabase          RevenueCat              │
│   ├─ Crashlytics     ├─ Auth           ├─ Subscriptions        │
│   ├─ Analytics       ├─ Database       └─ Paywalls             │
│   ├─ Remote Config   ├─ RLS Policies                           │
│   └─ AI (Gemini)     └─ Edge Functions                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
lib/
├── main.dart                     Entry point, service initialization
├── firebase_options.dart         Firebase config (auto-generated)
├── app/
│   ├── app.dart                 Root widget, lifecycle management
│   └── router.dart              GoRouter config, route guards
├── core/
│   ├── config/                  Configuration (ai_config, app_config)
│   ├── errors/                  Error classification (auth_errors)
│   ├── interfaces/              Service contracts for DI
│   ├── models/                  Freezed data models
│   ├── providers/               Riverpod providers
│   └── services/                Business logic (20 services)
├── features/                     Feature modules (9 modules)
│   ├── auth/                    Sign-in, lock screen
│   ├── error/                   Error display screens
│   ├── generate/                Multi-step generation wizard
│   ├── history/                 Past generations
│   ├── home/                    Occasion grid
│   ├── onboarding/              User education flow
│   ├── paywall/                 RevenueCat paywall
│   ├── results/                 Generated messages display
│   └── settings/                Account, feedback, legal
└── shared/
    ├── components/              Reusable widgets (flat structure)
    └── theme/                   Design tokens, colors, typography
```

---

## Key Architectural Patterns

### 1. Dependency Injection

**Pattern:** Interface-based DI with Riverpod providers

| Benefit | Implementation |
|---------|----------------|
| Testability | Provider overrides in tests |
| Loose coupling | Services depend on interfaces, not implementations |
| Single responsibility | One service per concern |

```dart
// Interface definition
abstract class IAuthService {
  Future<AuthResponse?> signInWithApple();
  Future<AuthResponse?> signInWithGoogle();
  Future<void> signOut();
}

// Provider registration with dependencies
final authServiceProvider = Provider<IAuthService>((ref) {
  return AuthService(
    supabaseAuth: ref.watch(supabaseAuthProvider),
    appleAuth: ref.watch(appleAuthProvider),
    googleAuth: ref.watch(googleAuthProvider),
  );
});
```

### 2. State Management (Riverpod 3.x)

| Provider Type | Use Case | Example |
|---------------|----------|---------|
| `Provider` | Service singletons | `authServiceProvider` |
| `StateNotifierProvider` | Complex state with listeners | `customerInfoProvider` |
| `StateProvider` | Simple mutable state | `selectedOccasionProvider` |
| `FutureProvider` | Async data | `checkProStatusProvider` |

**autoDispose Strategy:**

| State Type | autoDispose | Reason |
|------------|-------------|--------|
| Form state | Yes | Cleanup on screen dispose |
| User session | No | Survives navigation |
| Service providers | No | Singleton lifetime |

### 3. Error Handling

**AI Service Exception Hierarchy:**

```
AiException (abstract)
├── AiNetworkException       No connectivity
├── AiRateLimitException     Too many requests
├── AiContentBlockedException Safety filter triggered
├── AiUnavailableException   Service down (retryable)
├── AiEmptyResponseException No content returned
├── AiParseException         Invalid JSON response
├── AiTruncationException    Hit maxTokens (retryable)
└── AiServiceException       Catch-all
```

**Retry Configuration:**
- Exponential backoff with jitter
- Max 3 retries
- Only retryable exceptions trigger retry

### 4. Navigation (GoRouter)

**Route Protection:**

| Route Type | Behavior |
|------------|----------|
| Public (`/splash`, `/onboarding`) | Always accessible |
| Auth (`/auth/*`) | Accessible during auth flow |
| Protected (`/home`, `/generate/*`) | Requires onboarding completion |

---

## Authentication Architecture

### Multi-Provider Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Apple    │     │   Google    │
│   Sign-In   │     │   Sign-In   │
└──────┬──────┘     └──────┬──────┘
       │                   │
       ▼                   ▼
┌──────────────────────────────────────────────────────┐
│                    AuthService                        │
│  • SHA-256 nonce generation (replay prevention)      │
│  • Token extraction and validation                   │
│  • Provider-specific error handling                  │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│              SupabaseAuthProvider                     │
│  • signInWithIdToken() - OAuth token exchange        │
│  • Session management (JWT, auto-refresh)            │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│                 Post-Auth Actions                     │
│  • RevenueCat.identifyUser(userId)                   │
│  • UsageService.syncFromServer()                     │
│  • Navigate to /home                                 │
└──────────────────────────────────────────────────────┘
```

### Deep Link Configuration

| Type | URL Pattern | Handler |
|------|-------------|---------|
| OAuth Callback | `https://prosepal.app/auth/login-callback` | Supabase SDK |

---

## Subscription & Monetization

### Tier System

| Tier | Generations | Period | Enforcement |
|------|-------------|--------|-------------|
| Free | 1 | Lifetime (per device) | Client + server |
| Pro | 500 | Monthly (resetting) | Server-side RPC |

### RevenueCat Integration

```
┌─────────────────────────────────────────────────────┐
│                 SubscriptionService                  │
│  • initialize()        SDK setup                    │
│  • isPro()             Check 'pro' entitlement      │
│  • purchasePackage()   Complete purchase            │
│  • restorePurchases()  Restore from receipts        │
│  • customerInfoStream  Reactive updates             │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│              CustomerInfoNotifier                     │
│  • Listens to RevenueCat stream                      │
│  • Caches pro status in SharedPreferences            │
│  • Exposes isProProvider for UI reactivity           │
└──────────────────────────────────────────────────────┘
```

---

## AI Generation Pipeline

```
User Input
    │
    ▼
┌─────────────────────────────────────────────────────┐
│                  Input Validation                    │
│  • Connectivity check (DNS lookup, 3s timeout)      │
│  • Input sanitization (prompt injection defense)    │
│  • Length limits: name 50, details 500 chars        │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│                  Prompt Building                     │
│  • System instruction (ai_config.dart)              │
│  • Occasion/relationship/tone context               │
│  • Recipient personalization (optional)             │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│             Firebase AI (Gemini 2.5)                │
│  • Model: gemini-2.5-flash (via Remote Config)      │
│  • Safety: harassment, hate, explicit filters       │
│  • Timeout: 30 seconds                              │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│               Response Processing                    │
│  • Blocked content detection                        │
│  • Truncation detection (auto-retry)                │
│  • JSON parsing with schema validation              │
│  • UUID assignment + timestamps                     │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
             GenerationResult (3 messages)
```

---

## Data Persistence

| Data Type | Storage | Encryption | Scope |
|-----------|---------|------------|-------|
| Auth Session | Supabase SDK | JWT tokens | App-wide |
| Preferences | SharedPreferences | No | Local |
| Message History | Flutter Secure Storage | Platform encryption | Local |
| Device ID | Flutter Secure Storage | Platform encryption | Device |
| Logs | Memory buffer (200 max) | No | Session |

---

## Startup Sequence

```
main()
  │
  ├─ Preserve native splash
  ├─ Lock to portrait orientation
  │
  ├─ Firebase.initializeApp()
  │   └─ Set up Crashlytics error handlers
  │
  ├─ Firebase App Check (non-blocking)
  │
  ├─ Remote Config initialization
  │   └─ Check force update required
  │       └─ If true: ForceUpdateScreen → exit
  │
  ├─ AppConfig.validate()
  │
  ├─ Supabase.initialize()
  │
  ├─ SubscriptionService.initialize() [non-critical]
  │
  ├─ SharedPreferences.getInstance()
  │
  ├─ AuthService.initializeProviders() [pre-warm OAuth]
  │
  ├─ Create GoRouter with route guards
  │
  └─ runApp(ProviderScope with overrides)
      │
      └─ Remove native splash
```

---

## Configuration Management

### Build-Time (dart-define)

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `REVENUECAT_IOS_KEY` | RevenueCat iOS API key |
| `REVENUECAT_ANDROID_KEY` | RevenueCat Android API key |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth web client |
| `GOOGLE_IOS_CLIENT_ID` | Google OAuth iOS client |

### Runtime (Remote Config)

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `ai_model` | gemini-2.5-flash | Primary AI model |
| `ai_model_fallback` | gemini-2.5-flash-lite | Fallback model |
| `min_app_version_ios` | 1.0.0 | Force update threshold |
| `min_app_version_android` | 1.0.0 | Force update threshold |
| `force_update_enabled` | false | Toggle force updates |

---

## Monitoring & Observability

| Aspect | Tool | Data Collected |
|--------|------|----------------|
| Crashes | Firebase Crashlytics | Stack traces, device info, breadcrumbs |
| Analytics | Firebase Analytics | Screen views, events, user properties |
| Feature Flags | Firebase Remote Config | AI model, force update, toggles |
| Logging | In-memory buffer | Last 200 entries (PII redacted) |

---

## Testing Strategy

### Test Pyramid

| Level | Location | Purpose |
|-------|----------|---------|
| Unit | `test/services/`, `test/models/` | Services, models, utilities |
| Widget | `test/widgets/` | Screen rendering, interactions |
| Integration | `integration_test/journeys/` | User journeys (Patrol) |

### Mocking Pattern

Manual mocks without code generation for explicit control:

```dart
class MockAiService implements AiService {
  List<String> calls = [];
  GenerationResult? mockResult;

  @override
  Future<GenerationResult> generateMessages(...) async {
    calls.add('generateMessages');
    return mockResult ?? _defaultResult;
  }
}
```

### Verification References

- Test workflow, release gates, and operational verification: `docs/DEVOPS.md`
- Command quick reference: `test/README.md`
- Open issues and pending work: `docs/BACKLOG.md`

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| `SECURITY.md` | Security controls & OWASP compliance |
| `BACKLOG.md` | Outstanding work (burn-down list) |
| `test/README.md` | Test command quick reference |
| `LAUNCH_CHECKLIST.md` | Release checklist |
| `CLONING_PLAYBOOK.md` | Portfolio replication guide |

---

## Glossary

| Term | Definition |
|------|------------|
| DI | Dependency Injection - pattern for loose coupling |
| Freezed | Code generation library for immutable models |
| GoRouter | Declarative navigation library for Flutter |
| Riverpod | Reactive state management library |
| RLS | Row Level Security - Supabase database access control |
| RPC | Remote Procedure Call - Supabase server functions |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-11 | Development Team | Initial comprehensive architecture documentation |
