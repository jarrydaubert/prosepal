# Test Audit

> **Total: 716 tests passing** | Run: `flutter test`

---

## Test Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│  E2E / Integration Tests (integration_test/)                │
│  Real device, full user flows, external services            │
├─────────────────────────────────────────────────────────────┤
│  Widget Tests (test/widgets/)                               │
│  Screen rendering, navigation, user interactions            │
├─────────────────────────────────────────────────────────────┤
│  Unit Tests (test/services/, test/models/, test/errors/)    │
│  Pure logic, mocked dependencies, fast & isolated           │
└─────────────────────────────────────────────────────────────┘
```

> See `docs/SERVICE_ENDPOINTS.md` for endpoint-by-endpoint testing requirements.

---

## 1. Unit Tests

### 1.1 Services (`test/services/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `auth_service_with_mock_test.dart` | 72 | ✅ | All 11 auth methods + stream events |
| `subscription_service_with_mock_test.dart` | 74 | ✅ | All 7 RevenueCat methods |
| `biometric_service_mock_test.dart` | 35 | ✅ | All biometric flows |
| `ai_service_generation_test.dart` | 33 | ✅ | Response parsing, retry |
| `ai_service_test.dart` | 35 | ✅ | Exceptions, prompts |
| `ai_service_http_test.dart` | 30 | ✅ | HTTP mocking |
| `error_log_service_test.dart` | 15 | ✅ | Error logging |
| `review_service_test.dart` | 20 | ✅ | App review prompts |
| `usage_service_test.dart` | 8 | ⚠️ | Partial - needs unhappy paths |

### 1.2 Models (`test/models/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `models_test.dart` | 59 | ✅ | **Primary** - covers all models |
| `occasion_test.dart` | 19 | ⚠️ | Duplicate of above |
| `relationship_test.dart` | 13 | ⚠️ | Duplicate of above |
| `tone_test.dart` | 13 | ⚠️ | Duplicate of above |
| `message_length_test.dart` | 13 | ⚠️ | Duplicate of above |

**Issue:** Individual enum files duplicate `models_test.dart`. Consolidate into single file.

### 1.3 Errors (`test/errors/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `auth_errors_test.dart` | 25 | ✅ | All AuthException types |

### 1.4 Theme (`test/theme/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `app_colors_test.dart` | 15 | ✅ | Color definitions |
| `app_spacing_test.dart` | 12 | ✅ | Spacing tokens |

### 1.5 App (`test/app/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `app_lifecycle_test.dart` | 10 | ✅ | Lifecycle handling |

---

## 2. Mocks (`test/mocks/`)

### 2.1 Mock Classes

| File | Purpose |
|------|---------|
| `mock_auth_service.dart` | Simulates Supabase auth |
| `mock_subscription_service.dart` | Simulates RevenueCat |
| `mock_biometric_service.dart` | Simulates local_auth |
| `mocks.dart` | Barrel export |

### 2.2 Mock Self-Tests

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `mock_auth_service_test.dart` | 35 | ✅ | Validates mock behavior |
| `mock_subscription_service_test.dart` | 38 | ✅ | Validates mock behavior |
| `mock_biometric_service_test.dart` | 32 | ✅ | Validates mock behavior |

**Note:** These test the mocks themselves. Intentional, keep them.

---

## 3. Widget Tests (`test/widgets/`)

| File | Tests | Status | Notes |
|------|-------|--------|-------|
| `home_screen_test.dart` | 30 | ✅ | All occasions, navigation |
| `generate_screen_test.dart` | 50 | ✅ | Full wizard, errors |
| `results_screen_test.dart` | - | ❌ | **Missing** |
| `settings_screen_test.dart` | - | ❌ | **Missing** |
| `paywall_screen_test.dart` | - | ❌ | **Missing** |
| `auth_screen_test.dart` | - | ❌ | **Missing** |

---

## 4. Integration Tests (`integration_test/`)

| File | Status | Notes |
|------|--------|-------|
| `app_test.dart` | ⚠️ | Written, needs device run |
| `revenuecat_test.dart` | ⚠️ | Written, needs device run |
| `firebase_test.dart` | ⚠️ | Written, needs device run |

**Requirement:** Must run on real device or simulator, not CI.

---

## 5. Issues

### 5.1 Duplication

| Location | Issue | Action |
|----------|-------|--------|
| `test/models/` | 4 individual enum files duplicate `models_test.dart` | Merge into single file |
| `test/services/supabase_endpoints_test.dart` | Tests DB ops not used by app | Remove |

### 5.2 Missing Coverage

| Area | Gap | Priority |
|------|-----|----------|
| Widget tests | 4 screens missing | P2 |
| `usage_service_test.dart` | No unhappy paths | P3 |
| Integration tests | Not run on device | P1 |

---

## 6. CI/CD

**File:** `.github/workflows/ci.yml`  
**Budget:** `.github/BUDGET.md` (2,000 mins/month free tier)

| Job | Runner | Trigger | Billed |
|-----|--------|---------|--------|
| Analyze & Test | Linux | All PRs + pushes | ~2 min |
| Build iOS | macOS | Main only | ~80 min |
| Build Android | Linux | Main only | ~5 min |

**Current gaps:**
- No coverage threshold enforcement
- No integration test step

---

## 7. Commands

```bash
# All tests
flutter test

# By layer
flutter test test/services/
flutter test test/models/
flutter test test/widgets/
flutter test test/mocks/

# Single file
flutter test test/services/auth_service_with_mock_test.dart

# With coverage
flutter test --coverage

# Analyze
flutter analyze
```

---

## 8. Action Items

| Priority | Task | Status |
|----------|------|--------|
| P1 | Run integration tests on device | ⬜ |
| P2 | Create 4 missing widget tests | ⬜ |
| P2 | Consolidate model test files (5 → 1) | ⬜ |
| P3 | Add unhappy paths to `usage_service_test.dart` | ⬜ |
| P3 | Add coverage threshold to CI (70%) | ⬜ |

> See `docs/BACKLOG.md` for full improvement roadmap including onboarding, mocks, and CI enhancements.
