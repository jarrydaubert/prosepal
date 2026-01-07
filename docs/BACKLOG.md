# Backlog

> Actionable items only. High-level.

---

## Release Blockers (P0)

| Item | Action |
|------|--------|
| App Store ID | Add to `_rateApp()` and `review_service.dart` after approval |
| IAP Products | Submit in App Store Connect |

## Security - Server-Side Enforcement (P0)

> **CRITICAL:** Current usage enforcement is client-side only and can be bypassed.
> Must implement server-side validation before production monetization.

| Item | Location | Action |
|------|----------|--------|
| **Atomic usage increment RPC** | Supabase | Create `check_and_increment_usage` function that validates limits atomically |
| **Server-side limit check** | `usage_service.dart` | Call RPC before generation; fail if server rejects |
| **Device fingerprinting** | `usage_service.dart` | Replace SharedPreferences device flag with server-side tracking |
| **Rate limiting** | Supabase | Add IP/user rate limiting to prevent abuse |

### Supabase RPC Implementation (Reference)

```sql
-- Create atomic usage check + increment function
CREATE OR REPLACE FUNCTION check_and_increment_usage(
  p_user_id UUID,
  p_is_pro BOOLEAN,
  p_month_key TEXT
) RETURNS JSONB AS $$
DECLARE
  v_total_count INT;
  v_monthly_count INT;
  v_allowed BOOLEAN := FALSE;
BEGIN
  -- Get current usage with row lock
  SELECT total_count, monthly_count INTO v_total_count, v_monthly_count
  FROM user_usage
  WHERE user_id = p_user_id
  FOR UPDATE;
  
  -- Initialize if new user
  IF NOT FOUND THEN
    v_total_count := 0;
    v_monthly_count := 0;
  END IF;
  
  -- Check limits
  IF p_is_pro THEN
    v_allowed := v_monthly_count < 500; -- Pro monthly limit
  ELSE
    v_allowed := v_total_count < 1; -- Free lifetime limit
  END IF;
  
  -- Increment if allowed
  IF v_allowed THEN
    INSERT INTO user_usage (user_id, total_count, monthly_count, month_key, updated_at)
    VALUES (p_user_id, v_total_count + 1, v_monthly_count + 1, p_month_key, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
      total_count = EXCLUDED.total_count,
      monthly_count = CASE WHEN user_usage.month_key = p_month_key 
                      THEN EXCLUDED.monthly_count ELSE 1 END,
      month_key = EXCLUDED.month_key,
      updated_at = NOW();
  END IF;
  
  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'total_count', v_total_count + (CASE WHEN v_allowed THEN 1 ELSE 0 END),
    'monthly_count', v_monthly_count + (CASE WHEN v_allowed THEN 1 ELSE 0 END)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Technical Debt

| Item | Location | Notes |
|------|----------|-------|
| UsageService race condition | `usage_service.dart` | Atomic increment via Supabase RPC |
| Hardcoded usage limits | `usage_service.dart` | Move to remote config |
| Supabase singleton | `usage_service.dart` | Inject client for testability |
| Integration/E2E tests | `integration_test/` | Navigation flows: onboarding→auth→paywall→biometric |
| Re-auth for sensitive ops | `auth_service.dart` | Prompt re-auth before updateEmail/updatePassword/deleteAccount if session stale |
| Require env vars for keys | `auth_service.dart`, `subscription_service.dart` | Remove hardcoded defaults, require all keys via dart-define |
| Error injection in tests | `test/services/` | Add paths for simulating null ID tokens, network failures |
| Rate limiting auth attempts | `auth_service.dart` | Client-side exponential backoff for failed sign-ins |
| Paywall offering flexibility | `subscription_service.dart` | Support custom/specific offerings, not just default |
| Promotional offers | `subscription_service.dart` | Handle eligibility checks for promo offers |
| Pending purchase handling | `subscription_service.dart` | UI feedback for purchases in pending state |
| Biometric dialog localization | `biometric_service.dart` | Add authMessages for branded/localized prompts |
| Biometric timeout | `biometric_service.dart` | Expose authTimeout option for time-limited prompts |
| Biometric config validation | `biometric_service.dart` | Runtime checks for Info.plist/manifest setup |
| Secure storage integration | `biometric_service.dart` | Combine with flutter_secure_storage for sensitive data |
| History server sync | `history_service.dart` | Supabase sync for cross-device persistence (like UsageService) |
| History storage migration | `history_service.dart` | Migrate to hive/sqflite for larger data support |
| History export/share | `history_service.dart` | Allow users to export history as JSON |
| Form state consolidation | `providers.dart` | Consolidate form StateProviders into single NotifierProvider |
| AutoDispose for transient state | `providers.dart` | Add autoDispose to generation result/error providers |
| Auth screen localization | `auth_screen.dart` | Extract strings to .arb files |
| Auth screen accessibility | `auth_screen.dart` | Add Semantics widgets, verify contrast ratios |
| Google button branding | `auth_screen.dart` | Verify google_g.png is official asset or use SDK button |
| Auth analytics events | `auth_screen.dart` | Track sign-in attempts/success for funnel analysis |
| Email auth localization | `email_auth_screen.dart` | Extract strings to .arb files |
| Email auth accessibility | `email_auth_screen.dart` | Add Semantics widgets, verify contrast ratios |
| Sign-up integration | `email_auth_screen.dart` | Link to sign-up screen or auto-detect new users |

---

## Known Issues

| Issue | Severity |
|-------|----------|
| Supabase session persists in Keychain | Low |
| No offline banner | Low |
| HomeScreen usage indicator tests failing (3) | Low |

---

## Compliance (v1.1)

| Item | Notes |
|------|-------|
| Data export feature | GDPR right to portability - export user data as JSON |
| Analytics opt-out | Settings toggle to disable Firebase Analytics |
| Apple Privacy Labels | Fill in App Store Connect (similar to Play Data Safety) |
| Apple token revocation | Call Apple revocation endpoint on account delete |

---

## Observability & Analytics

| Item | Location | Notes |
|------|----------|-------|
| Auth flow analytics | `auth_service.dart` | Anonymized events for sign-in success/failure rates |
| Purchase funnel analytics | `subscription_service.dart` | Track paywall views, purchase attempts, conversions |
| Email confirmation redirects | `auth_service.dart` | Handle Supabase email confirmation flow properly |

---

## v1.1 Features

### Core
- Regeneration option ("Generate More")
- Message history / favorites
- Feedback (thumbs up/down per message)
- Pull-to-refresh on home
- Occasion search/filter

### Security
- Lifecycle re-auth (biometrics on resume)
- Passcode fallback
- Apple token revocation on delete
- Encrypted history storage

### Enhancements
- More tones (Sarcastic, Nostalgic, Poetic)
- "Make it rhyme" toggle
- Multi-language (Spanish, French)
- Tablet/landscape layout

### Integrations
- Birthday reminders + push notifications
- Shareable card preview (image export)
- Photo integration (Gemini multimodal)

---

## Future Ideas (v2.0+)

- International expansion (Japan)
- Group messages
- Scheduling
- Address book sync

---

## ASO Metadata

**iOS App Name:** `Prosepal - Card Message Writer`
**iOS Subtitle:** `AI Birthday & Thank You Notes`
**Keywords:** `greeting card writer,thank you note,wedding message,sympathy card,get well,anniversary,graduation`
**Category:** Utilities / Lifestyle
**Age Rating:** 4+

**Screenshot Captions:**
1. "The right words, right now"
2. "Birthday, wedding, sympathy & more"
3. "Tailored to your relationship"
4. "3 unique messages in seconds"
5. "Funny, warm, or formal"
6. "Standing in the card aisle? We've got you"
