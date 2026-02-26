# Backlog

> Actionable items only. High-level. No status updates.

---

## Release Blockers (P0)

| Item | Action |
|------|--------|
| App Store ID | Add to `_rateApp()` after approval |
| IAP Products | Submit in App Store Connect |

---

## Priority Matrix

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P1 | Bold styling (paywall screen) | Low | High |
| P2 | GenUI SDK - AI-generated card designs | Medium | High |
| P4 | Dark mode | High | Medium |

---

## Testing

> See `USER_JOURNEYS.md` for complete E2E flows with expected logs.
> See `TESTING.md` for edge cases and known issues.

### Test Files
| File | Purpose |
|------|---------|
| `app_test.dart` | Mocked Patrol tests (auth, AI errors, 52 tests) |
| `e2e_test.dart` | Firebase Test Lab entry point |
| `journeys/` | Modular journey tests (j1-j10, 75 tests) |
| `coverage/` | Exhaustive option coverage (66 tests) |

### Log Coverage (Complete ✅)
| Service/Screen | Logs Added |
|----------------|------------|
| biometric_service | enable/disable/auth events ✅ |
| auth_service | sign in/out/delete events ✅ |
| onboarding_screen | started/completed ✅ |
| lock_screen | shown ✅ |
| home_screen | wizard started + occasion ✅ |
| results_screen | copy/share with option # ✅ |
| app.dart | backgrounded/resumed ✅ |
| diagnostic_service | internal warning logs ✅ |

### Known Issues

| ID | Issue | Severity |
|----|-------|----------|
| L5 | User stuck after 3 failed biometrics | Medium |
| R3 | Supabase session persists in Keychain | Low |
| O1 | No offline banner | Low |

---

## v1.1 Post-Launch Features

### Results Screen Enhancements
- **Regeneration option** - "Generate More" or "Tweak Prompt" button for iteration
- **Pro differentiation** - Additional message options, longer formats for Pro users
- **Message history** - Save favorites, view past generations
- **Feedback integration** - Thumbs up/down per message for AI improvement
- **In-app rating prompt** - Trigger after successful copy (use existing `in_app_review`)

### Home Screen Enhancements
- **Pull-to-refresh** - Sync usage/subscription state on pull gesture
- **Occasion search/filter** - Search bar or categories for 41+ occasions
- **Recent activity** - Show last generated messages or popular occasions
- **Tablet/landscape layout** - Responsive grid columns for larger screens

### Lock Screen Enhancements
- **Lifecycle re-auth** - Re-prompt biometrics on resume from background
- **Passcode fallback** - In-app PIN/passcode if biometrics unavailable
- **Attempt throttling** - Add delays after failed attempts

### Auth Service Enhancements
- **MFA support** - TOTP or recovery codes via Supabase MFA
- **Rate limiting** - Exponential backoff for transient network errors
- **Apple token revocation** - Call Apple revocation endpoint on delete
- **Deep link config** - Extract scheme to constants/config provider

### Biometric Service Enhancements
- **Strong biometrics** - Enforce BiometricType.strong (Class 3) for sensitive ops
- **Capability caching** - Memoize availableBiometrics results
- **Reactive state** - Expose enabled state via Riverpod notifier

### Log Service Enhancements
- **Structured keys** - Use setCustomKey() for frequently logged params
- **Debug verbosity** - Add configurable filter for debug output
- **Analytics linkage** - Optional Firebase Analytics event with logs
- **Rate limiting** - Sampling in release for high-volume scenarios

### Testing Enhancements
- **Custom Patrol finders** - Key-based semantics for pivotal elements
- **Native dialog handling** - Use Patrol native interactions for dialogs
- **Pro-specific tests** - Validate Pro user behaviors and unlimited generation
- **Restore purchase outcomes** - Mock and verify success/failure flows
- **Platform-specific tests** - iOS/Android variations (Apple sign-in, biometrics)

### Birthday Reminders + Push Notifications
- Supabase `contacts` table (name, birthday, relationship)
- Firebase Cloud Messaging setup
- Cloud Function for daily reminder checks
- Simple "Add Contact" UI in app

### Shareable Card Preview
- Render message on card background template
- Export as image (`RepaintBoundary` + screenshot)
- Share to iMessage/WhatsApp/social

### Photo Integration
- `image_picker` for photo selection
- Gemini multimodal to incorporate photo context into message
- "I love this photo of us at..." style personalization

---

## Future Ideas

### Prosepal Enhancements
- Group messages (multiple recipients, collaborative tone)
- Scheduling ("Send me this on Dec 25 at 9am")
- Address book sync (pull birthdays from contacts)

### Portfolio Expansion (Clone Strategy)

**Approach:** Use Droid CLI for rapid market intel → JSON → code gen. Inspire heavily but differentiate with unique UX (animations, mobile-first).

| Target | Clone From | Our Differentiator |
|--------|------------|-------------------|
| EmailPal | Writesonic/Copy.ai | Mobile-first, occasion templates |
| CaptionPal | Copy.ai social | One-tap copy, trending hooks |
| BioWriter | Rytr | Dating/LinkedIn presets, swipe UI |
| ToastMaster | Generic AI | Speech pacing, teleprompter mode |

**Safe Line:** Features/logic ok to clone. Avoid exact UI/copy/branding (trademark risk).

**Workflow:**
1. Scrape competitor (public pages) → structured JSON
2. Prompt Droid: "Inspire from [JSON] but build unique mobile app with [our animations/polish]"
3. Same Flutter stack, different prompts/UI skin
4. Undercut pricing ($4.99 vs $20+)

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
