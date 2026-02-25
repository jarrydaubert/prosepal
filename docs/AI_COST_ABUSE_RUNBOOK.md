# AI Cost And Abuse Controls Runbook

## Purpose

Operationalize and verify AI abuse protection and cost controls before release.

This runbook is the source of truth for `VNEXT-10`.

## Scope

- Firebase AI Logic / Gemini runtime controls
- App Check posture for AI requests
- API key restrictions
- Rate-limit and quota controls
- Budget and alerting controls
- Remote Config kill-switch response

## Current Runtime Controls (Code)

- App Check initialized at startup:
  - Android: `AndroidPlayIntegrityProvider` (release), `AndroidDebugProvider` (debug)
  - Apple: `AppleAppAttestWithDeviceCheckFallbackProvider` (release), `AppleDebugProvider` (debug)
  - Reference: `lib/main.dart`
- AI client uses App Check and optional limited-use tokens:
  - `FirebaseAI.googleAI(appCheck: FirebaseAppCheck.instance, useLimitedUseAppCheckTokens: ...)`
  - Reference: `lib/core/services/ai_service.dart`
- Remote Config kill switches and schema:
  - `config_schema_version`
  - `ai_enabled`
  - `paywall_enabled`
  - `premium_enabled`
  - Reference: `lib/core/services/remote_config_service.dart`, `docs/REMOTE_CONFIG_TEMPLATE.json`
- Model allowlist validation:
  - Invalid model IDs are rejected and replaced with safe defaults.
  - Reference: `lib/core/config/ai_config.dart`, `lib/core/services/remote_config_service.dart`
- Per-user/device rate limiting:
  - Server-side: `20/min per user`, `30/min per device`
  - Local fallback: `10/min`
  - Reference: `lib/core/services/rate_limit_service.dart`
- Usage limits:
  - Free: `1` lifetime generation
  - Pro: `500/month`
  - Reference: `lib/core/services/usage_service.dart`

## Verification Command

Run:

```bash
./scripts/audit_ai_cost_controls.sh
```

The script checks:
- Required APIs enabled
- API key restriction posture
- Budget visibility / configured budget presence (if permissions allow)

## Evidence Handling

- Do not store time-bound audit results in this runbook.
- Store per-run audit output in release evidence artifacts.
- Any failure discovered by the audit must be tracked in `docs/BACKLOG.md`.

## Manual Verification Checklist

### 1) API And App Restrictions

- Confirm all Firebase auto-created keys have:
  - API target restrictions (minimum)
  - Application restrictions for platform keys:
    - Android key: package + SHA-1/256
    - iOS key: bundle ID
    - Browser key: allowed referrers (production domains only; no localhost/127.0.0.1)
- Confirm AI key(s) restricted to `generativelanguage.googleapis.com`.
- Do not keep standalone Gemini API keys without app/server restrictions.
  - Exception: Firebase-managed `Gemini Developer API key (auto created by Firebase)`.

### 2) App Check Production Posture

- Firebase AI Logic App Check mode set to `Enforce` for production.
- Verify Android provider behavior on production build.
- Verify Apple provider behavior on production build.
- If limited-use tokens are disabled, document reason and planned enablement date.

### 3) Rate Limits / Quotas

- Supabase RPC `check_rate_limit` thresholds confirmed:
  - user: `20/min`
  - device: `30/min`
- Local fallback remains conservative at `10/min`.
- Firebase AI quota dashboards reviewed for expected monthly/weekly envelope.

### 4) Budget Alerts

- Billing budget exists on open billing account.
- At least two alerts configured:
  - warning threshold (for example 50%)
  - critical threshold (for example 80-90%)
- Notification channels confirmed (email and/or pager channel).

### 5) Kill-Switch Drill

- Publish `ai_enabled=false` in Remote Config.
- Confirm generation is blocked with graceful user error.
- Re-enable `ai_enabled=true` and verify recovery.
- Record publish timestamp and operator.

## Incident Response (Cost Spike Or Abuse Spike)

When AI cost or abuse spikes unexpectedly:

1. Immediate containment (0-15 min)
- Set `ai_enabled=false` in Remote Config.
- If monetization exploit suspected, set `paywall_enabled=false` or `premium_enabled=false` as needed.
- Announce incident in ops channel with timestamp.

2. Triage (15-60 min)
- Check Firebase AI request/token trends.
- Check Supabase RPC rate-limit hit rates and error ratios.
- Check crash/error signals for auth/purchase/generation.

3. Remediation (same day)
- Tighten server-side rate-limit thresholds if needed.
- Tighten API key restrictions if gaps exist.
- Re-enable AI progressively via Remote Config after stability confidence.

4. Follow-up
- Add backlog item with root cause and prevention actions.
- Update this runbook with any threshold/process changes.

## Evidence Log (Fill Per Release Candidate)

- Date:
- Operator:
- Project:
- Audit script result:
- API key restriction result:
- App Check enforcement result:
- Budget alert result:
- Kill-switch drill result:
- Approval for release gate:
