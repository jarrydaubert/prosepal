# Prosepal Security Overview

---
**Document Control**

| Field | Value |
|-------|-------|
| Version | 1.1.0 |
| Classification | Internal |
| Owner | Development Team |
| Last Reviewed | 2026-01-11 |
| Next Review | 2026-07-11 |

---

## Scope

This document covers security controls for the Prosepal mobile application:

**In Scope:**
- iOS and Android mobile applications
- Supabase backend (auth, database, edge functions)
- Firebase services (AI, analytics, crashlytics, remote config)
- RevenueCat payment integration

**Out of Scope:**
- prosepal-web marketing site (separate security review)
- Third-party service internal security (covered by vendor SOC 2/compliance)
- Physical security of user devices

---

## Security Architecture

Prosepal implements security controls appropriate for a content/utility mobile application. Our security approach is based on:

- **Defense in depth**: Multiple layers of protection
- **Least privilege**: Minimal permissions and access
- **Fail secure**: Default to denial when controls fail
- **Privacy by design**: Minimal data collection, user control

### Threat Model

Primary threats addressed:
1. **API abuse**: Unauthorized use of AI generation (cost impact)
2. **Account takeover**: Unauthorized access to user accounts
3. **Free tier gaming**: Circumventing usage limits
4. **Data exposure**: Unauthorized access to user data

Risk tolerance: Low for auth/payment, medium for content features.

---

## Authentication & Authorization

| Control | Implementation | Location |
|---------|----------------|----------|
| OAuth Providers | Apple Sign-In, Google Sign-In | `auth_service.dart` |
| Email/Password | Supabase Auth | `supabase_auth_provider.dart` |
| Magic Links | Supabase OTP | `supabase_auth_provider.dart` |
| Session Management | Supabase JWT (1-hour expiry, auto-refresh) | Supabase SDK |
| Global Sign Out | `SignOutScope.global` | `supabase_auth_provider.dart:325` |
| Biometric Lock | iOS FaceID/TouchID, Android BiometricPrompt | `biometric_service.dart` |
| Session Timeout | 60s background triggers biometric re-auth (if enabled) | `app.dart:34` |
| Re-auth Gate | 5-minute window for sensitive operations | `reauth_service.dart` |

### OAuth Security Details

**Apple Sign-In:**
- SHA-256 hashed nonce prevents replay attacks (`auth_service.dart:167-171`)
- Authorization code exchanged server-side for refresh token
- Refresh token stored in `apple_credentials` table for revocation compliance

**Google Sign-In:**
- Native SDK with server client ID validation
- Lightweight auth attempted first (cached session)
- ID token validated by Supabase

### Authentication Throttling

| Control | Implementation | Location |
|---------|----------------|----------|
| Client-side throttle | Exponential backoff (1s-60s) | `auth_throttle_service.dart` |
| Failure threshold | 3 attempts before throttling | `auth_throttle_service.dart:48` |
| Server-side limits | Supabase built-in rate limiting | Supabase config |

---

## API Protection

| Control | Implementation | Location |
|---------|----------------|----------|
| Firebase App Check | PlayIntegrity (Android), AppAttest (iOS) | `main.dart:94-100` |
| Rate Limiting | Server-side primary, client fallback | `rate_limit_service.dart` |
| Device Fingerprinting | `identifierForVendor` (iOS), `androidId` (Android) | `device_fingerprint_service.dart` |
| Request Timeouts | 30 seconds | `supabase_auth_provider.dart:92` |

### Rate Limiting Architecture

```
Request → Client Check → Server RPC → Allow/Deny
              ↓ (if server unavailable)
         Local Fallback (fail-closed, conservative limits)
```

| Limit Type | Threshold | Window |
|------------|-----------|--------|
| Per-user (server) | 20 requests | 1 minute |
| Per-device (server) | 30 requests | 1 minute |
| Local fallback | 10 requests | 1 minute |

**Fail behavior:** Fail-closed - if server check fails, local limits apply.

---

## Data Protection

### Data Classification

| Classification | Examples | Storage | Encryption |
|----------------|----------|---------|------------|
| Sensitive | Auth tokens, biometric prefs | `flutter_secure_storage` | Hardware-backed |
| Internal | Usage counts, rate limits | `SharedPreferences` / Supabase | Transit only |
| Public | App preferences, theme | `SharedPreferences` | None required |

### In Transit

| Control | Implementation | Location |
|---------|----------------|----------|
| HTTPS Only | `cleartextTrafficPermitted="false"` | `network_security_config.xml` |
| iOS ATS | Default enabled | iOS platform |
| TLS Version | 1.2+ (platform default) | System |

### At Rest

| Data Type | Storage | Encryption |
|-----------|---------|------------|
| Auth tokens | `flutter_secure_storage` | iOS Keychain, Android EncryptedSharedPreferences |
| Biometric preference | `flutter_secure_storage` | Hardware-backed |
| User preferences | `SharedPreferences` | Platform default |
| Message history | Local device | Not encrypted (user content) |
| Server data | Supabase | Encrypted at rest (Supabase managed) |

### Data Retention

| Data Type | Retention | Deletion Trigger |
|-----------|-----------|------------------|
| Auth session | Until sign-out or 7-day refresh expiry | Sign out / expiry |
| Usage counts | Indefinite (for limits) | Account deletion |
| Rate limit logs | 24 hours (sliding window) | Automatic cleanup |
| Message history (local) | Until app uninstall | User action |
| Crash logs | 90 days | Firebase policy |
| Analytics | 14 months | Firebase policy |

### Data Minimization

- No unnecessary PII collection
- Message history stored locally by default (not synced unless authenticated)
- Usage counts track quantities only (no content stored)
- Device fingerprints are platform-provided IDs (not custom tracking)

---

## Privacy Controls

| Control | Implementation | Location |
|---------|----------------|----------|
| PII Redaction | Log sanitization in release builds | `log_service.dart:149-184` |
| Analytics Consent | User toggle respects preference | `main.dart:72-84` |
| Account Deletion | Edge function with cascade delete | `delete-user/index.ts` |
| Data Export | JSON export capability | `data_export_service.dart` |
| Log Buffer Clear | Cleared on sign out | `log_service.dart:128-130` |

### PII Keys Redacted in Logs

```dart
// log_service.dart:149-167
static const _piiKeys = {
  'email', 'password', 'token', 'accessToken', 'refreshToken',
  'idToken', 'personalDetails', 'recipientName', 'prompt',
  'message', 'text', 'content', 'response', 'name', 'displayName',
  'phone', 'address',
};
```

### Apple App Store Compliance

| Requirement | Implementation |
|-------------|----------------|
| Sign In with Apple | Supported as primary OAuth option |
| Account Deletion | Full deletion via edge function |
| Token Revocation | Apple refresh tokens revoked on delete |
| Privacy Nutrition Label | Matches actual data collection |

### GDPR-Aligned Practices

| Right | Implementation |
|-------|----------------|
| Right to Erasure | Account deletion with cascade delete |
| Right to Access | Data export functionality |
| Right to Rectification | User can update profile in settings |
| Data Minimization | Minimal collection, local-first storage |
| Consent | Analytics opt-in/out in settings |

> **Note:** "GDPR-aligned" indicates design intent; formal compliance certification not pursued.

---

## Input Validation & Sanitization

| Control | Implementation | Location |
|---------|----------------|----------|
| Prompt Injection Prevention | Regex filter for injection patterns | `ai_service.dart:588-609` |
| Input Length Limits | Name: 50 chars, Details: 500 chars | `ai_config.dart` |
| Server-side Validation | Supabase RLS policies | Database config |

### Prompt Injection Patterns Filtered

```dart
// ai_service.dart:590-607
final injectionPatterns = RegExp(
  r'(ignore\s+(previous|above|all)\s+instructions?|'
  r'system\s*:|assistant\s*:|user\s*:|'
  r'\[INST\]|\[/INST\]|<\|im_start\|>|<\|im_end\|>|'
  r'<<SYS>>|<</SYS>>|'
  r'###\s*(instruction|system|human|assistant)|'
  r'you\s+are\s+now\s+|pretend\s+to\s+be\s+|act\s+as\s+if\s+|'
  r'disregard\s+|forget\s+(everything|all|previous))',
  caseSensitive: false,
);
```

---

## Code Security

| Control | Implementation | Location |
|---------|----------------|----------|
| ProGuard/R8 | Enabled for Android release | `build.gradle.kts:75-80` |
| Code Obfuscation | Flutter default + ProGuard rules | Build config |
| Debug Detection | No debug backdoors (verified) | Code audit |
| Config Validation | Release fails on missing critical config | `app_config.dart:101-131` |
| Test Store Safeguard | Assert prevents sandbox in production | `subscription_service.dart:102-111` |

### Build Security

```kotlin
// build.gradle.kts - Release build type
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

---

## Infrastructure Security

### Supabase

| Control | Implementation |
|---------|----------------|
| Row Level Security (RLS) | Enabled on all tables |
| Service Role Key | Server-side only (edge functions) |
| Anon Key | Client-side (safe - RLS protected) |
| JWT Validation | All authenticated endpoints |
| Edge Functions | Privileged operations only |

### Firebase

| Control | Implementation |
|---------|----------------|
| App Check | PlayIntegrity (Android), AppAttest (iOS) |
| API Key Restrictions | Package name / bundle ID restricted |
| Crashlytics | Error monitoring (PII redacted) |
| Remote Config | Force update capability |

### RevenueCat

| Control | Implementation |
|---------|----------------|
| API Key Security | Platform-specific keys via dart-define |
| Entitlement Verification | Server-side via SDK |
| Test Store Protection | Assert blocks sandbox in release |

---

## Edge Functions Security

| Function | Purpose | Auth | Service Role Used |
|----------|---------|------|-------------------|
| `delete-user` | Account deletion + Apple token revocation | JWT required | Yes (for admin.deleteUser) |
| `exchange-apple-token` | Store Apple refresh token | JWT required | Yes (for table write) |

### Security Model

1. **User verification**: JWT validated via anon key client
2. **Privilege separation**: Service role only for admin operations
3. **Error sanitization**: Internal details not exposed to client
4. **Logging**: User ID prefix logged (privacy-safe)

---

## Third-Party Security

### Vendor Assessment

| Vendor | Service | Compliance | Security Review |
|--------|---------|------------|-----------------|
| Supabase | Auth, Database, Functions | SOC 2 Type II | [Trust Center](https://supabase.com/security) |
| Firebase/Google | AI, Analytics, Crashlytics | ISO 27001, SOC 2 | [Security Page](https://firebase.google.com/support/privacy) |
| RevenueCat | Payments, Subscriptions | SOC 2 Type II | [Security Page](https://www.revenuecat.com/security) |
| Apple | Sign In, App Store | Platform security | N/A (platform) |
| Google | Sign In, Play Store | Platform security | N/A (platform) |

### Dependency Management

- Flutter/Dart dependencies via `pub.dev`
- Security advisories monitored via GitHub Dependabot (when enabled)
- Critical updates applied within 7 days
- Non-critical updates reviewed monthly

---

## OWASP Mobile Top 10 Assessment

| Category | Status | Notes |
|----------|--------|-------|
| M1: Improper Platform Usage | Pass | Proper Keychain/Keystore usage |
| M2: Insecure Data Storage | Pass | Sensitive data in secure storage |
| M3: Insecure Communication | Pass | HTTPS enforced, no cleartext |
| M4: Insecure Authentication | Partial | OAuth re-auth for sensitive ops planned (see Roadmap) |
| M5: Insufficient Cryptography | Pass | Platform crypto (SHA256, ES256) |
| M6: Insecure Authorization | Pass | Supabase RLS enforced |
| M7: Client Code Quality | Pass | Input validation, error handling |
| M8: Code Tampering | Pass | ProGuard + App Check |
| M9: Reverse Engineering | Acceptable | ProGuard provides reasonable protection |
| M10: Extraneous Functionality | Pass | No debug backdoors |

### M4 Detail

**Current state:** OAuth users (Apple/Google) without biometrics enabled see only a confirmation dialog for sensitive operations (email change, account deletion).

**Gap:** No cryptographic verification of user identity for OAuth users without biometrics.

**Mitigation:** Biometric re-auth available; OAuth re-auth planned for v1.1.

---

## Incident Response

### Detection

| Source | What's Detected | Alert Mechanism |
|--------|-----------------|-----------------|
| Firebase Crashlytics | App crashes, non-fatal errors | Firebase Console |
| Firebase Analytics | Unusual usage patterns | Custom alerts |
| Supabase Logs | Auth failures, RLS violations | Supabase Dashboard |
| RevenueCat | Payment anomalies | RevenueCat Dashboard |

### Response Capabilities

| Capability | Mechanism | Time to Effect |
|------------|-----------|----------------|
| Force app update | Remote Config `min_app_version` | Next app launch |
| Disable feature | Remote Config flags | Next app launch |
| Rate limit adjustment | Supabase RPC parameters | Immediate |
| Global sign out | Supabase session invalidation | Immediate |
| Block device | Device fingerprint blocklist | Immediate |

### Incident Severity Levels

| Severity | Definition | Response Time |
|----------|------------|---------------|
| Critical | Data breach, auth bypass, payment fraud | Immediate |
| High | Significant abuse, service degradation | < 4 hours |
| Medium | Limited abuse, non-critical bugs | < 24 hours |
| Low | Minor issues, improvement opportunities | Next sprint |

---

## Security Roadmap

### Planned Improvements

| Item | Priority | Target | Status |
|------|----------|--------|--------|
| CAPTCHA on email auth | Medium | v1.1 | Planned |
| OAuth re-authentication for sensitive ops | High | v1.1 | Planned |
| Configurable session timeout | Low | v1.2 | Backlog |
| Persist auth throttle to secure storage | Low | v1.2 | Backlog |

### Considered but Deferred

| Item | Reason |
|------|--------|
| Certificate pinning | Maintenance burden outweighs benefit for app type; cloud providers handle cert rotation |
| Jailbreak/root detection | Removed - overkill for content app; causes false positives |
| Screen capture prevention | Users need to screenshot/share generated messages |

---

## Vulnerability Disclosure Policy

### Reporting Security Issues

**Email:** security@prosepal.app

**What to include:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Your contact information (for follow-up)

### Response Commitment

| Severity | Acknowledgment | Target Resolution |
|----------|----------------|-------------------|
| Critical | 24 hours | 7 days |
| High | 48 hours | 30 days |
| Medium | 72 hours | 90 days |
| Low | 1 week | Next major release |

### Safe Harbor

We will not pursue legal action against security researchers who:
- Act in good faith to avoid privacy violations and data destruction
- Do not access or modify other users' data
- Report vulnerabilities promptly and allow reasonable time for remediation
- Do not publicly disclose until we've had opportunity to address

### Out of Scope

- Denial of service attacks
- Social engineering of staff
- Physical attacks
- Third-party services (report to them directly)

---

## Audit History

| Date | Type | Scope | Auditor | Findings | Status |
|------|------|-------|---------|----------|--------|
| 2026-01-11 | Internal code review | Full application | Development Team | 0 Critical, 2 High, 5 Medium | High items in roadmap |

### Audit Methodology

- Manual code review of security-critical paths
- OWASP Mobile Top 10 checklist
- Authentication flow analysis
- Data flow mapping
- Third-party integration review

---

## Glossary

| Term | Definition |
|------|------------|
| ATS | App Transport Security - iOS feature enforcing HTTPS |
| JWT | JSON Web Token - signed auth token format |
| RLS | Row Level Security - Supabase database access control |
| App Check | Firebase feature validating app authenticity |
| Nonce | Number used once - prevents replay attacks in OAuth |
| OWASP | Open Web Application Security Project |
| PII | Personally Identifiable Information |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1.0 | 2026-01-11 | Development Team | Added document control, scope, threat model, data retention, third-party security, expanded disclosure policy, glossary, changelog. Fixed M4 OWASP status. |
| 1.0.0 | 2026-01-10 | Development Team | Initial security documentation |
