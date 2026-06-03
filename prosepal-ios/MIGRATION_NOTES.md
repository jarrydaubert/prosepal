# Migration Notes

## App Store Continuity

Preferred direction, subject to App Store Connect verification:

- same Apple Developer Team
- same bundle ID if viable
- same App Store Connect listing if viable
- same subscription product IDs if viable
- same RevenueCat entitlement ID: `pro`

The native rewrite should use separate debug/internal bundle IDs until the
release identity decision is explicit.

## Local Data

If the native app ships over the existing bundle ID, it may inherit the app
container. That does not mean Flutter plugin storage formats are automatically
safe to read from Swift.

Migration candidates:

- onboarding completion
- spelling preference
- analytics and crash-report preferences
- paywall dismissal cooldown
- local usage display cache
- persisted anonymous RevenueCat ID
- generation history
- saved occasions/reminders
- biometric preference

Migration rules:

- Treat server state as authoritative where available.
- Import personal message history only through a tested, format-aware path.
- Record a native migration marker after a successful import.
- On parse failure, fail safe and preserve the legacy data where practical.
- Do not rebind anonymous usage or pending sync state to a later signed-in user.

