# Prosepal Features

## Generation
- 40 occasions (Birthday, Thank You, Sympathy, Wedding, + 36 more)
- 14 relationships (Close Friend → Community Member)
- 9 tones (Heartfelt, Casual, Funny, Formal, Inspirational, Playful, Sarcastic, Nostalgic, Poetic)
- 3 lengths (Brief, Standard, Detailed)
- Recipient name personalization
- Personal details/context (500 char)
- UK/US spelling (auto-detected from locale, toggle in settings)
- 3 unique messages per generation

## AI
- Google Gemini via Firebase AI
- System instruction for consistent output
- Retry with exponential backoff
- Model fallback via Remote Config
- Input sanitization

## Results
- Copy to clipboard (per message)
- Regenerate (same inputs, new messages)
- Share app prompt after copy
- History auto-save (secure storage)
- View/copy/delete past messages

## Auth
- Sign in with Apple
- Sign in with Google
- Anonymous usage (1 free, no sign-in)
- Account linking
- Delete account with data cleanup

## Subscription
- Free: 1 message lifetime
- Pro: 500 messages/month
- RevenueCat integration
- Restore purchases
- Webhook sync to Supabase
- Paywall after onboarding + when exhausted

## Settings
- British spelling toggle
- Biometric lock (Face ID / Touch ID)
- Analytics opt-out
- Data export (JSON)
- Help & FAQ link
- Send feedback form
- Rate app prompt
- Terms / Privacy Policy

## Onboarding
- 3-page intro
- Progress bar
- Pro teaser
- Paywall on completion

## Infrastructure
- Remote Config (model switching, force update)
- Firebase Analytics + Crashlytics
- Structured logging
- Client + server rate limiting
- Review prompt after 3rd generation

## Platforms
- iOS 15.0+
- Android API 23+

## Verification Matrix

Use the commands and evidence paths in [DEVOPS.md](./DEVOPS.md) for runnable
validation. Each row names the behavior that needs an explicit pass/fail oracle
when it is changed.

| Area | Behavior |
|------|----------|
| Happy path | Fresh install reaches onboarding, free generation completes, and copy works. |
| Happy path | Sign-in, Pro upgrade, and generation converge on the expected entitlement state. |
| Happy path | Regenerate returns a different generated option for the same inputs. |
| Happy path | History exposes previous messages and copy remains available. |
| Edge cases | No-network conditions show a deterministic error state. |
| Edge cases | Exhausted free quota opens the paywall path. |
| Edge cases | Rate limits show user-facing guidance without consuming usage incorrectly. |
| Edge cases | Long details input remains bounded and does not break generation or layout. |
| Settings | British spelling preference is reflected in output behavior. |
| Settings | Biometric lock can be enabled, disabled, and exercised through app lifecycle transitions. |
| Settings | Analytics opt-out is respected by telemetry setup and event emission. |
| Settings | Data export produces valid JSON for the current user state. |
| Settings | Delete account removes app-owned user data through the supported cleanup path. |
| Subscription | Purchase grants access after entitlement reconciliation. |
| Subscription | Restore finds an existing subscription and updates app state. |
| Subscription | Expired entitlement returns the user to the correct free-tier behavior. |
