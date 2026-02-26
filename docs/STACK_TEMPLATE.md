# Flutter App Stack Template (December 2025)

Reusable configuration for future Flutter apps. Copy this setup for consistent, production-ready apps.

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Framework** | Flutter | 3.38.5 | Cross-platform UI |
| **Language** | Dart | ^3.9.0 | Null safety, records |
| **State** | Riverpod | 3.0.3 | Reactive state management |
| **Navigation** | go_router | 17.0.1 | Declarative routing |
| **AI** | google_generative_ai | 0.4.7 | Gemini 2.5 Flash |
| **Auth** | Supabase | 2.12.0 | Auth, database, edge functions |
| **Payments** | RevenueCat | 9.10.2 | Subscriptions & IAP |
| **Biometrics** | local_auth | 3.0.0 | Face ID / Touch ID |

---

## Third-Party Services

### Authentication: Supabase
**Dashboard:** https://supabase.com/dashboard

| Feature | Implementation |
|---------|----------------|
| Email/Password | `signInWithPassword()`, `signUp()` |
| Apple Sign-In | `signInWithIdToken()` + native credential |
| Google OAuth | `signInWithOAuth()` |
| Magic Link | `signInWithOtp()` |
| Password Reset | `resetPasswordForEmail()` |

**Setup:**
1. Create project at supabase.com
2. Enable providers in Auth > Providers
3. Add redirect URLs: `com.yourbundle.app://login-callback`
4. Copy URL and anon key to app

**Edge Functions (for account deletion - App Store requirement):**
```bash
supabase functions deploy delete-user --project-ref YOUR_PROJECT_REF
```

### Payments: RevenueCat
**Dashboard:** https://app.revenuecat.com

| Platform | Setup Required |
|----------|----------------|
| iOS | App Store Connect > In-App Purchases > Create products |
| Android | Google Play Console > Monetization > Products |

**Product ID Convention:**
- `com.yourapp.pro.monthly` - Monthly subscription
- `com.yourapp.pro.yearly` - Yearly subscription
- `com.yourapp.credits.100` - Consumable

**Integration:**
1. Create app in RevenueCat
2. Add API keys to app
3. Create Entitlements (e.g., "pro")
4. Create Offerings with packages

### Email: Resend + Cloudflare
**Resend Dashboard:** https://resend.com
**Cloudflare Dashboard:** https://dash.cloudflare.com

**Free Tiers:**
- Resend: 100 emails/day, 3,000/month
- Cloudflare: Unlimited DNS, free SSL

**Setup:**
1. Buy domain on Cloudflare ($12-15/yr for .app)
2. Add domain in Resend
3. Add DNS records to Cloudflare:
   - MX record
   - TXT (SPF)
   - CNAME (DKIM)
4. Use Resend's Supabase integration (auto-configures SMTP)

**SMTP Settings (if manual):**
```
Host: smtp.resend.com
Port: 465
User: resend
Password: re_xxxxxxxxxxxx (API key)
From: noreply@yourdomain.app
```

### AI: Google Gemini
**Console:** https://aistudio.google.com

**Model Selection (Dec 2025):**
| Model | Use Case | Cost |
|-------|----------|------|
| gemini-2.5-flash | Fast, cheap, most tasks | $0.0375/1M tokens |
| gemini-2.5-pro | Complex reasoning | $1.25/1M tokens |

**Safety Settings:**
```dart
safetySettings: [
  SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
  SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
  SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
  SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
]
```

---

## Project Structure (Feature-First + Atomic Design)

```
lib/
├── main.dart
├── app/
│   └── router.dart
├── core/
│   ├── errors/           # Error handling
│   ├── models/           # Data models
│   ├── providers/        # Riverpod providers
│   └── services/         # Business logic
│       ├── ai_service.dart
│       ├── auth_service.dart
│       ├── biometric_service.dart
│       ├── subscription_service.dart
│       └── usage_service.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── settings/
│   ├── onboarding/
│   └── paywall/
├── shared/
│   ├── atoms/            # Buttons, cards, icons
│   ├── molecules/        # Composed widgets
│   ├── organisms/        # Feature sections
│   └── theme/
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       └── app_typography.dart
└── assets/
    └── images/
        └── logo.png
```

---

## iOS Configuration

### Bundle ID Convention
`com.yourcompany.appname`

### Info.plist Keys
```xml
<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to unlock AppName</string>

<!-- Apple Sign-In (add capability in Xcode) -->
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>

<!-- Deep Links -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.yourcompany.appname</string>
    </array>
  </dict>
</array>
```

### Capabilities (Xcode)
- Sign in with Apple
- Push Notifications (if needed)
- Associated Domains (for universal links)

---

## Android Configuration

### build.gradle
```gradle
android {
    defaultConfig {
        minSdk = 24
        targetSdk = 35
    }
}
```

### AndroidManifest.xml
```xml
<!-- Biometrics -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>

<!-- Deep Links -->
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.yourcompany.appname" />
</intent-filter>
```

---

## CI/CD: GitHub Actions

**Budget-conscious workflow (free tier: 2,000 mins/month):**

| Job | Runner | Multiplier | Time |
|-----|--------|------------|------|
| Analyze | ubuntu-latest | 1x | ~2 min |
| Test | ubuntu-latest | 1x | ~3 min |
| Build Android | ubuntu-latest | 1x | ~10 min |
| Build iOS | macos-latest | **10x** | ~15 min |

**Strategy:** Run iOS builds only on `main` push, not PRs.

---

## Email Templates (Supabase)

### Confirm Sign Up
**Subject:** `Confirm your AppName account`
```html
<h2>Welcome to AppName!</h2>
<p>Thanks for signing up. Please confirm your email:</p>
<p><a href="{{ .ConfirmationURL }}" style="display:inline-block;padding:12px 24px;background:#6366f1;color:white;text-decoration:none;border-radius:8px;">Confirm Email</a></p>
<p style="color:#666;font-size:12px;">If you didn't create an account, ignore this email.</p>
```

### Magic Link
**Subject:** `Sign in to AppName`
```html
<h2>Sign in to AppName</h2>
<p>Click below to sign in:</p>
<p><a href="{{ .ConfirmationURL }}" style="...">Sign In</a></p>
<p style="color:#666;font-size:12px;">This link expires in 24 hours.</p>
```

### Reset Password
**Subject:** `Reset your AppName password`
```html
<h2>Reset Your Password</h2>
<p>We received a request to reset your password.</p>
<p><a href="{{ .ConfirmationURL }}" style="...">Reset Password</a></p>
<p style="color:#666;font-size:12px;">If you didn't request this, ignore this email.</p>
```

---

## Supabase Edge Function: Account Deletion

**Required for App Store compliance.**

```typescript
// supabase/functions/delete-user/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  
  // Verify user
  const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } }
  })
  const { data: { user } } = await userClient.auth.getUser()
  if (!user) return new Response('Invalid user', { status: 401 })

  // Delete with admin privileges
  const adminClient = createClient(supabaseUrl, supabaseServiceKey)
  await adminClient.auth.admin.deleteUser(user.id)

  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
```

**Deploy:**
```bash
supabase functions deploy delete-user --project-ref YOUR_PROJECT_REF
```

---

## Testing Strategy

| Test Type | Tool | Target |
|-----------|------|--------|
| Unit | flutter_test | Services, models, pure logic |
| Widget | flutter_test | UI components |
| Integration | integration_test | Full flows |

**Coverage Target:** 70%+ for MVP, 80%+ for launch

**Run:**
```bash
flutter test                          # All tests
flutter test --coverage               # With coverage
flutter test test/services/           # Specific folder
flutter test integration_test/        # E2E tests on device
```

---

## Service & Integration Testing

> See `docs/INTEGRATION_TESTING.md` for complete testing guide.

### Testing Hierarchy

```
┌────────────────────────────────────────────┐
│ E2E Integration (integration_test/)        │ ← Device required
├────────────────────────────────────────────┤
│ Widget Tests (test/widgets/)               │ ← CI automated
├────────────────────────────────────────────┤
│ Unit Tests (test/services/)                │ ← CI automated
└────────────────────────────────────────────┘
```

### Mock Packages (Unit Tests)

| Service | Mock Package | Purpose |
|---------|--------------|---------|
| Supabase | `mock_supabase_http_client` | Database & auth mocking |
| Firebase | `firebase_core_platform_interface` | Core mocking |
| RevenueCat | **Test Store API key** | Instant mock purchases |
| Google AI | `package:http/testing.dart` | HTTP response mocking |

### RevenueCat Key Usage (CRITICAL)

```dart
// ✅ CORRECT: Test Store for ALL automated tests
static const _testStoreKey = 'test_xxx'; // CI, unit tests, development

// ✅ CORRECT: Production key for manual sandbox testing only
static const _iosKey = 'appl_xxx'; // Apple Sandbox, TestFlight

// ⚠️ NEVER use production key for automated tests!
// ⚠️ Real charges possible, dashboard pollution
```

| Environment | API Key | Use Case |
|-------------|---------|----------|
| **Unit Tests / CI** | Test Store (`test_xxx`) | Automated, free, instant |
| **Manual Device Testing** | Production (`appl_xxx`) | Apple Sandbox testers |
| **TestFlight** | Production (`appl_xxx`) | Beta users |
| **Production** | Production (`appl_xxx`) | Live users |

### Test Case Categories

| Category | Examples |
|----------|----------|
| **Happy Path** | Valid input → expected result |
| **Unhappy Path** | Invalid credentials, rate limits, network errors |
| **Edge Cases** | Empty responses, null values, malformed data |
| **Manual Only** | Biometrics, Apple Sign In, real purchases |

---

## Pre-Launch Checklist

### App Store Requirements
- [ ] Account deletion functionality
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] App icons (all sizes)
- [ ] Screenshots (6.5", 5.5")
- [ ] App description & keywords

### Technical
- [ ] Production API keys (not test keys)
- [ ] Custom SMTP configured
- [ ] Error tracking (Crashlytics/Sentry)
- [ ] Analytics events
- [ ] Deep links tested

### RevenueCat
- [ ] Products created in App Store Connect
- [ ] Products imported to RevenueCat
- [ ] Entitlements configured
- [ ] Offerings set up
- [ ] Sandbox testing passed

---

## Cost Summary (Monthly)

| Service | Free Tier | Paid |
|---------|-----------|------|
| Supabase | 500MB DB, 50K auth users | $25/mo |
| RevenueCat | $2.5K MTR | 1% + $0.04 after |
| Resend | 3,000 emails/mo | $20/mo (50K) |
| Cloudflare | Unlimited DNS | Free |
| Gemini API | $0 (free tier) | Pay per token |
| GitHub Actions | 2,000 mins/mo | $0.008/min |

**MVP Cost: $0-15/month** (domain renewal only)

---

## Legal (App Store Required)

### In-App Legal Screens
Keep Terms & Privacy in-app (not external URLs) for better UX:

```
lib/features/settings/legal_screen.dart
├── TermsScreen
├── PrivacyScreen
└── _LegalSection (reusable component)
```

**Content Guidelines:**
- Keep it concise - only what's necessary
- AI disclosure required: "Content generated by [AI Model]. Outputs may vary."
- Link from auth screen: "By continuing, you agree to our Terms and Privacy Policy"

### Age Rating
For AI content apps without social features: **4+** is typically fine.

---

## Quick Start for New App

```bash
# 1. Create Flutter project
flutter create --org com.yourcompany appname
cd appname

# 2. Add dependencies
flutter pub add flutter_riverpod go_router supabase_flutter purchases_flutter google_generative_ai local_auth

# 3. Copy this structure
# - lib/core/services/
# - lib/features/
# - lib/shared/

# 4. Set up services
# - Supabase: Create project, enable auth providers
# - RevenueCat: Create app, add products
# - Cloudflare: Buy domain
# - Resend: Add domain, integrate with Supabase

# 5. Configure
# - iOS: Info.plist, capabilities
# - Android: build.gradle, AndroidManifest.xml

# 6. Deploy Edge Function
supabase functions deploy delete-user

# 7. Test & launch!
```

---

*Last updated: December 2025*
