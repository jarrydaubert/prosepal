# Service Endpoints

Active native iOS endpoint inventory.

## Native Staging Gateway

```text
https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
```

Xcode Run environment key:

```text
PROSEPAL_GATEWAY_URL
```

Staging dev guard header:

```text
X-ProsePal-Dev-Gateway-Secret
```

The secret value must remain local-only and must never be printed, committed, or
placed in shared schemes.

## Supabase Auth

Configured through:

```text
PROSEPAL_SUPABASE_URL
PROSEPAL_SUPABASE_ANON_KEY
```

Sign in with Apple exchanges through Supabase Auth in the native app.

## App Store / StoreKit

Production app identity:

```text
com.prosepal.prosepal
```

Staging/UAT must use the existing production app identity plus staging runtime
configuration where possible. Do not create multiple public ProsePal apps.

Side-by-side staging uses the internal/UAT bundle identity:

```text
com.prosepal.prosepal.staging
```

That identity is implemented in the tracked Xcode project as `ProsePal Staging`
and must be paired with matching Apple Developer, Sign in with Apple,
StoreKit/App Store Connect, and Supabase staging configuration before it is
treated as fully testable.

Product IDs:

```text
com.prosepal.pro.yearly
com.prosepal.pro.monthly
com.prosepal.pro.weekly
```

Server-side entitlement endpoints live under `supabase/functions/`:

- `app-store-notifications`
- `app-store-reconcile-entitlement`

These are staging/proof work until App Store Server Notifications V2,
reconciliation, sandbox purchase, expiry, and refund paths are evidenced.

## Archived Flutter Endpoints

Firebase AI, Remote Config, RevenueCat, and Flutter SDK endpoint details are
historical. Use `docs/legacy-flutter/` or the archive refs:

- `flutter-prod-freeze-2026-06-25`
- `legacy/flutter-production-reference`
