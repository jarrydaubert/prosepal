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
- Email magic link
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

---

## Test Checklist

**Happy Path**
- [ ] Fresh install → onboarding → free gen → copy
- [ ] Sign in → Pro upgrade → generate
- [ ] Regenerate → copy different option
- [ ] History → copy old message

**Edge Cases**
- [ ] No network → error state
- [ ] Free exhausted → paywall
- [ ] Rate limited → message shown
- [ ] Long details → truncated

**Settings**
- [ ] British spelling → reflected in output
- [ ] Biometrics toggle works
- [ ] Analytics opt-out respected
- [ ] Data export → valid JSON
- [ ] Delete account → cleanup

**Subscription**
- [ ] Purchase → immediate access
- [ ] Restore → finds subscription
- [ ] Expires → reverts to free

*Updated: 2026-02-11*
