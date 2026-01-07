# User Journeys

> Complete E2E flows with expected logs. Each action = test case + log verification.

---

## Screen Map

| Screen | File | Entry Points |
|--------|------|--------------|
| Onboarding | `onboarding_screen.dart` | Fresh install |
| Auth | `auth_screen.dart` | Sign in required |
| Email Auth | `email_auth_screen.dart` | Email option selected |
| Home | `home_screen.dart` | After onboarding/auth |
| Generate | `generate_screen.dart` | Occasion tapped |
| Results | `results_screen.dart` | Generation complete |
| Settings | `settings_screen.dart` | Settings icon |
| Paywall | `custom_paywall_screen.dart` | Upgrade tapped |
| Lock | `lock_screen.dart` | Biometrics enabled + app foreground |
| Biometric Setup | `biometric_setup_screen.dart` | Post-auth if available |
| Feedback | `feedback_screen.dart` | Settings > Feedback |
| Legal | `legal_screen.dart` | Privacy/Terms tapped |

---

## Journey 1: Fresh Install → Free Generation → Close

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Launch app | Splash | - | F1.1 |
| 2 | See onboarding | Onboarding | `[INFO] Onboarding started` | F1.1 |
| 3 | Swipe/tap Continue (x3) | Onboarding | - | F1.2 |
| 4 | Complete onboarding | Home | `[INFO] Onboarding completed` | F1.2 |
| 5 | See home with occasions | Home | - | F1.3 |
| 6 | See "1 free remaining" | Home | - | Anon.2 |
| 7 | Tap Birthday | Generate | `[INFO] Wizard started` | F2.1 |
| 8 | Select Close Friend | Generate | - | F2.1 |
| 9 | Tap Continue | Generate | - | F2.2 |
| 10 | Select Heartfelt | Generate | - | F2.2 |
| 11 | Tap Continue | Generate | - | F2.3 |
| 12 | See Generate button | Generate | - | F2.3 |
| 13 | Tap Generate Messages | Generate | `[INFO] AI generation started` | F8.1 |
| 14 | See loading | Generate | - | F8.1 |
| 15 | See 3 results | Results | `[INFO] AI generation success` | F8.2 |
| 16 | Tap Copy | Results | `[INFO] Message copied` | F8.3 |
| 17 | See "Copied!" | Results | - | F8.3 |
| 18 | Close app | - | `[INFO] App backgrounded` | - |

### Log Events (Firebase Crashlytics)
```
[INFO] Onboarding started
[INFO] Onboarding completed
[INFO] Wizard started | occasion=birthday
[INFO] AI generation started | occasion=birthday, relationship=closeFriend, tone=heartfelt
[INFO] AI calling generateContent...
[INFO] AI response received
[INFO] AI parsed 3 messages
[INFO] AI generation success | count=3, occasion=birthday
[INFO] Message copied | option=1
[INFO] App backgrounded
```

---

## Journey 2: Return User → Upgrade → Purchase

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Launch app (0 remaining) | Home | `[INFO] App launched` | F4.1 |
| 2 | See "0 free remaining" | Home | - | F4.1 |
| 3 | Tap Birthday | Generate | `[INFO] Wizard started` | F4.2 |
| 4 | Complete wizard | Generate | - | F4.2 |
| 5 | See "Upgrade to Continue" | Generate | - | Anon.3 |
| 6 | Tap Upgrade | Auth | `[INFO] Upgrade tapped, auth required` | F4.2 |
| 7 | Sign in (Apple/Google) | Auth | `[INFO] Sign in started` | Manual |
| 8 | Auth success | Paywall | `[INFO] User signed in` | Manual |
| 9 | See subscription options | Paywall | `[INFO] Paywall offerings loaded` | F4.2 |
| 10 | Select Monthly | Paywall | - | Manual |
| 11 | Complete purchase | Paywall | `[INFO] Purchase completed` | Manual |
| 12 | See PRO badge | Home | `[INFO] Pro status updated` | Pro.1 |

### Log Events
```
[INFO] App launched | remainingGenerations=0
[INFO] Wizard started | occasion=birthday
[INFO] Upgrade tapped, auth required
[INFO] Sign in started | provider=apple
[INFO] User signed in | userId=xxx...
[INFO] RevenueCat user identified | userId=xxx...
[INFO] Paywall offerings loaded | packages=3
[INFO] Purchase completed | hasPro=true
[INFO] Pro status updated | isPro=true
```

---

## Journey 3: Pro User → Generate → Sign Out

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Launch app (Pro) | Home | `[INFO] App launched` | Pro.1 |
| 2 | See PRO badge | Home | - | Pro.1 |
| 3 | Tap any occasion | Generate | `[INFO] Wizard started` | Pro.2 |
| 4 | Complete wizard | Generate | - | Pro.2 |
| 5 | Tap Generate | Generate | `[INFO] AI generation started` | F8.1 |
| 6 | See results | Results | `[INFO] AI generation success` | F8.2 |
| 7 | Tap Start Over | Home | - | F8.4 |
| 8 | Tap Settings | Settings | - | F3.1 |
| 9 | See Pro Plan | Settings | - | Pro.3 |
| 10 | Scroll to Sign Out | Settings | - | Auth.1 |
| 11 | Tap Sign Out | Dialog | `[INFO] Sign out initiated` | Auth.1 |
| 12 | Tap Confirm | Auth | `[INFO] User signed out` | Auth.2 |
| 13 | See Auth screen | Auth | `[INFO] RevenueCat user logged out` | Auth.2 |

### Log Events
```
[INFO] App launched | isPro=true
[INFO] Wizard started | occasion=thankYou
[INFO] AI generation started | occasion=thankYou, relationship=colleague, tone=formal
[INFO] AI generation success | count=3
[INFO] Sign out initiated
[INFO] User signed out
[INFO] RevenueCat user logged out
[INFO] Usage cleared
```

---

## Journey 4: Enable Biometrics → Lock/Unlock

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Sign in | Home | `[INFO] User signed in` | Manual |
| 2 | Tap Settings | Settings | - | F3.1 |
| 3 | See biometric toggle | Settings | - | F12.1 |
| 4 | Enable biometrics | Settings | `[INFO] Biometrics enable requested` | Manual |
| 5 | System prompt | Settings | - | Manual |
| 6 | Authenticate | Settings | `[INFO] Biometrics enabled` | Manual |
| 7 | Close app | - | `[INFO] App backgrounded` | - |
| 8 | Reopen app | Lock | `[INFO] Lock screen shown` | Manual |
| 9 | Authenticate | Lock | `[INFO] Biometric auth started` | Manual |
| 10 | Success | Home | `[INFO] Biometric auth success` | Manual |

---

## Journey 5: Delete Account

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Settings > Delete Account | Dialog | `[INFO] Delete account initiated` | Auth.3 |
| 2 | See warning | Dialog | - | Auth.3 |
| 3 | Tap Delete | Auth | `[INFO] Account deleted` | Manual |
| 4 | Data cleared | Auth | `[INFO] User data cleared` | Manual |

---

## Journey 6: AI Error → Retry

### Steps
| # | Action | Screen | Expected Log | Test |
|---|--------|--------|--------------|------|
| 1 | Tap Generate (offline) | Generate | `[INFO] AI generation started` | AIErr.1 |
| 2 | See error | Generate | `[ERROR] Firebase AI error` | AIErr.1 |
| 3 | Dismiss error | Generate | - | AIErr.4 |
| 4 | Retry | Generate | `[INFO] AI generation started` | AIErr.4 |
| 5 | Success | Results | `[INFO] AI generation success` | AIErr.4 |

---

## Test Coverage Matrix

| Journey | Scenario Tests | Golden Path | Manual |
|---------|---------------|-------------|--------|
| 1: Fresh → Free Gen | Anon.* | F1-F2, F8 | - |
| 2: Upgrade → Purchase | Anon.3 | F4 | StoreKit |
| 3: Pro → Sign Out | Pro.*, Auth.* | F3 | - |
| 4: Biometrics | - | - | Manual |
| 5: Delete Account | Auth.3 | - | Manual |
| 6: AI Error → Retry | AIErr.* | - | - |

---

## Journey 7: Reinstall (Anonymous) → Fresh State

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Delete app | - | - |
| 2 | Reinstall | - | - |
| 3 | Launch | Onboarding | `[INFO] Fresh install detected` |
| 4 | Complete onboarding | Home | `[INFO] Onboarding completed` |
| 5 | See 1 free remaining | Home | - |

---

## Journey 8: Reinstall (Pro) → Restore

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Delete app (was Pro) | - | - |
| 2 | Reinstall + launch | Home (0 free) | - |
| 3 | Sign in (same account) | Home | `[INFO] User signed in` |
| 4 | RevenueCat restores | PRO badge | `[INFO] RevenueCat user identified` |
| 5 | Usage synced | Server count | `[INFO] Usage restored from server` |

---

## Journey 9: Multiple Accounts

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Sign in Account A | Pro badge | `[INFO] User signed in` |
| 2 | Generate message | Success | `[INFO] AI generation success` |
| 3 | Sign out | Auth screen | `[INFO] User signed out` |
| 4 | Sign in Account B | Free badge | `[INFO] User signed in` |
| 5 | Usage isolated | B's count | `[INFO] Usage synced from server` |

---

## Journey 10: App Background/Resume

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Mid-wizard, background app | - | `[INFO] App backgrounded` |
| 2 | Resume app | Lock (if bio) or wizard | `[INFO] App resumed` |
| 3 | State preserved | Same step | - |
| 4 | Complete wizard | Results | `[INFO] AI generation success` |

---

## Journey 11: Orientation Change

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Start wizard | Step 1 | - |
| 2 | Rotate device | State preserved | - |
| 3 | Complete wizard | Results | - |
| 4 | Rotate on results | Cards reflow | - |

---

## v1.1 Journeys (Post-Launch)

### Journey 12: Birthday Reminders

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Settings > Add Contact | Contact form | `[INFO] Contact form opened` |
| 2 | Enter name + birthday | - | - |
| 3 | Save contact | Contacts list | `[INFO] Contact saved` |
| 4 | Day before birthday | Push notification | `[INFO] Reminder triggered` |
| 5 | Tap notification | Generate (prefilled) | `[INFO] Deep link opened` |

**Edge Cases:**
- Notification permission denied → Nudge in settings
- Offline when reminder due → Queue locally

---

### Journey 13: Shareable Card Preview

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Generate messages | Results | - |
| 2 | Tap Share as Card | Preview modal | `[INFO] Card preview opened` |
| 3 | See message on card | Rendered image | - |
| 4 | Tap Share | System sheet | `[INFO] Share initiated` |
| 5 | Send via iMessage | Sent | `[INFO] Share completed` |

**Edge Cases:**
- No share permission → Fallback to copy text
- Cancel share → Return to preview

---

### Journey 14: Photo Integration

| # | Action | Expected | Log |
|---|--------|----------|-----|
| 1 | Wizard step 3 | Details input | - |
| 2 | Tap Add Photo | Photo picker | `[INFO] Photo picker opened` |
| 3 | Select photo | Thumbnail shown | `[INFO] Photo selected` |
| 4 | Generate | AI uses photo | `[INFO] AI generation started` |
| 5 | Results | "I love this photo..." | `[INFO] AI generation success` |

**Edge Cases:**
- Permission denied → Explain why needed
- Large image → Compress before upload
- No photo → Normal generation

---

## Edge Cases (All Journeys)

### Performance
| Case | Expected | Test |
|------|----------|------|
| Slow network (>5s) | Loading indicator stays | F7.1 |
| Generation timeout (30s) | Error message | AIErr.* |
| Large details (>500 chars) | Truncation warning | - |

### Platform
| Case | Expected | Test |
|------|----------|------|
| iOS low battery | Normal operation | Manual |
| Do Not Disturb | Notifications queued | Manual |
| App kill mid-generation | Resume from home | F7.1 |

### Abuse Prevention
| Case | Expected | Test |
|------|----------|------|
| Rapid generate taps | Debounced | F7.1 |
| Anonymous reinstall abuse | New free token (acceptable) | J7 |
| Pro limit (500/mo) | Soft block + message | - |

---

---

## Test Coverage Summary (Updated)

### Journey Test Files
| File | Journey | Tests |
|------|---------|-------|
| j1_fresh_install_test.dart | Fresh Install → Free Gen | 11 |
| j2_upgrade_flow_test.dart | Upgrade → Auth → Paywall | 7 |
| j3_pro_generate_test.dart | Pro User Flow | 7 |
| j4_settings_test.dart | Settings & Account | 12 |
| j5_navigation_test.dart | Navigation & Back | 7 |
| j6_error_resilience_test.dart | Errors & Edge Cases | 8 |
| j7_restore_flow_test.dart | Reinstall & Restore | 5 |
| j8_paywall_test.dart | Paywall Display | 4 |
| j9_wizard_details_test.dart | Length, Name, Details | 7 |
| j10_results_actions_test.dart | Copy, Share, Start Over | 7 |

### Coverage Tests
| File | What | Tests |
|------|------|-------|
| occasions_test.dart | All 40 occasions | 40 |
| relationships_test.dart | All 14 relationships | 14 |
| tones_test.dart | All 6 tones + combos | 11 |

**Total: ~140 E2E tests**

---

## Manual Testing Required

| Feature | Why Manual |
|---------|------------|
| Apple/Google Sign In | OAuth requires real device + account |
| Sandbox Purchase | StoreKit sandbox only |
| Biometric Lock/Unlock | Hardware required |
| Push Notifications | v1.1 feature |
| Share to iMessage | System sheet |
