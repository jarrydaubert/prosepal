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
| `scenario_tests.dart` | Mocked Patrol tests (auth, AI errors) |
| `golden_path_test.dart` | Firebase Test Lab (60+ real device tests) |

### Log Coverage Gaps (P1)
| Service/Screen | Missing Logs |
|----------------|--------------|
| biometric_service | enable/disable/auth events |
| auth_service | sign in/out/delete events |
| onboarding_screen | started/completed |
| lock_screen | shown/auth events |
| generate_screen | wizard started |
| results_screen | copy/share events |

### Known Issues

| ID | Issue | Severity |
|----|-------|----------|
| L5 | User stuck after 3 failed biometrics | Medium |
| R3 | Supabase session persists in Keychain | Low |
| O1 | No offline banner | Low |

---

## v1.1 Post-Launch Features

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
