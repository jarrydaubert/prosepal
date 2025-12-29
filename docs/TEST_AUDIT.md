# Test Audit

> **503 tests passing** | Run: `flutter test`

---

## Philosophy

Tests should catch real issues, not pad metrics. Every test must answer: **"What bug would this catch?"**

**Keep tests that:**
- Verify business logic (auth flows, subscription states, AI parsing)
- Catch regressions in user-facing flows (screens, navigation)
- Validate error handling (network failures, invalid states)
- Test edge cases that have caused bugs before

**Delete tests that:**
- Test static values (colors, spacing constants)
- Test mock helpers instead of real code
- Duplicate coverage from other tests
- Would never fail in practice

---

## Test Pyramid

```
┌─────────────────────────────────────────────────────────────┐
│  Integration Tests (integration_test/)                      │
│  Device-only, real SDKs, critical user flows                │
│  Target: 5-10 tests covering happy paths                    │
├─────────────────────────────────────────────────────────────┤
│  Widget Tests (test/widgets/)                               │
│  Screen rendering, navigation, user interactions            │
│  Target: Every screen with user-facing logic                │
├─────────────────────────────────────────────────────────────┤
│  Unit Tests (test/services/, test/models/)                  │
│  Business logic with mocked dependencies                    │
│  Target: 90%+ coverage on services                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Current Coverage

### Services (`test/services/`)

| Service | Tests | Coverage | Notes |
|---------|-------|----------|-------|
| `auth_service_test.dart` | 53 | ✅ Full | Real AuthService with DI mocks |
| `subscription_service_test.dart` | 74 | ✅ Full | All RevenueCat methods |
| `biometric_service_test.dart` | 35 | ✅ Full | LocalAuth with mocks |
| `ai_service_test.dart` | 35 | ✅ Full | Prompt building, errors |
| `ai_service_generation_test.dart` | 33 | ✅ Full | Response parsing |
| `ai_service_http_test.dart` | 30 | ✅ Full | HTTP layer |
| `auth_service_crypto_test.dart` | 12 | ✅ Full | Nonce, SHA256 |
| `auth_service_compliance_test.dart` | 15 | ✅ Full | App Store requirements |
| `error_log_service_test.dart` | 15 | ✅ Full | Error logging |
| `review_service_test.dart` | 20 | ✅ Full | In-app review |
| `usage_service_test.dart` | 8 | ⚠️ Partial | Needs error paths |

### Models (`test/models/`)

| File | Tests | Notes |
|------|-------|-------|
| `models_test.dart` | 59 | All enums, GeneratedMessage, GenerationResult |

### Errors (`test/errors/`)

| File | Tests | Notes |
|------|-------|-------|
| `auth_errors_test.dart` | 25 | AuthException types and messages |

### Widgets (`test/widgets/`)

| Screen | Tests | Notes |
|--------|-------|-------|
| `home_screen_test.dart` | 30 | Occasions grid, navigation |
| `generate_screen_test.dart` | 50 | Full wizard flow, errors |
| `results_screen_test.dart` | - | ❌ Missing |
| `settings_screen_test.dart` | - | ❌ Missing |

### App (`test/app/`)

| File | Tests | Notes |
|------|-------|-------|
| `app_lifecycle_test.dart` | 10 | Foreground/background handling |

### Mocks (`test/mocks/`)

Mock classes for DI - no tests on mocks themselves (deleted as low-value).

| Mock | Purpose |
|------|---------|
| `mock_auth_service.dart` | Full auth simulation |
| `mock_subscription_service.dart` | RevenueCat simulation |
| `mock_biometric_service.dart` | Biometric simulation |
| `mock_apple_auth_provider.dart` | Apple Sign In DI |
| `mock_google_auth_provider.dart` | Google Sign In DI |
| `mock_supabase_auth_provider.dart` | Supabase Auth DI |

---

## Integration Tests (`integration_test/`)

Run on device only: `flutter test integration_test/`

| Test | Status | Purpose |
|------|--------|---------|
| `app_test.dart` | ⚠️ Device | App launch, basic navigation |
| `revenuecat_test.dart` | ⚠️ Device | SDK init, offerings, purchase flow |
| `firebase_test.dart` | ⚠️ Device | Firebase init, AI generation |

---

## Action Items

| Priority | Task | Status |
|----------|------|--------|
| P1 | Run integration tests on iOS device | ⬜ |
| P2 | Add `results_screen_test.dart` | ⬜ |
| P2 | Add `settings_screen_test.dart` | ⬜ |
| P3 | Add error paths to `usage_service_test.dart` | ⬜ |

---

## Commands

```bash
# All unit/widget tests
flutter test

# By layer
flutter test test/services/
flutter test test/widgets/

# Single file
flutter test test/services/auth_service_test.dart

# With coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration (requires device)
flutter test integration_test/
```

---

## Deleted (Low-Value)

Previously had 782 tests. Removed 279 that didn't catch real bugs:

- `test/theme/` - Static color/spacing constants
- `test/mocks/*_test.dart` - Tested mocks, not real code  
- `test/models/occasion_test.dart` etc. - Duplicated `models_test.dart`
- `test/widget_test.dart` - Empty placeholder

> Tests should fail when code breaks, not just exist for coverage metrics.
