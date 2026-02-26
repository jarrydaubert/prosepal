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
| 4 | Enable biometrics | Settings | `[INFO] Biometrics enable requested` | **MISSING** |
| 5 | System prompt | Settings | - | Manual |
| 6 | Authenticate | Settings | `[INFO] Biometrics enabled` | **MISSING** |
| 7 | Close app | - | `[INFO] App backgrounded` | - |
| 8 | Reopen app | Lock | `[INFO] Lock screen shown` | **MISSING** |
| 9 | Authenticate | Lock | `[INFO] Biometric auth started` | **MISSING** |
| 10 | Success | Home | `[INFO] Biometric auth success` | **MISSING** |

### Missing Logs (Need to Add)
```dart
// biometric_service.dart
Log.info('Biometrics enable requested');
Log.info('Biometrics enabled');
Log.info('Biometrics disabled');
Log.info('Biometric auth started');
Log.info('Biometric auth success');
Log.info('Biometric auth failed', {'error': error.name});

// lock_screen.dart
Log.info('Lock screen shown');
```

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

## Log Coverage Audit

### Services with Logging ✅
| Service | Info | Warn | Error |
|---------|------|------|-------|
| ai_service | ✅ | ✅ | ✅ |
| subscription_service | ✅ | ✅ | ✅ |
| usage_service | ✅ | ✅ | ✅ |
| diagnostic_service | ✅ | - | - |
| router | ✅ | ✅ | - |

### Services Missing Logging ❌
| Service | Needed |
|---------|--------|
| biometric_service | Enable/disable, auth start/success/fail |
| auth_service | Sign in/out, delete account |
| review_service | Review prompted, submitted |

### Screens Missing Logging ❌
| Screen | Needed |
|--------|--------|
| onboarding_screen | Started, completed |
| lock_screen | Shown, auth attempt |
| settings_screen | Biometric toggle, sign out tap |
| generate_screen | Wizard started, step navigation |
| results_screen | Copy, share, regenerate |
| home_screen | Occasion selected |

---

## Test Coverage Matrix

| Journey | Scenario Tests | Golden Path | Manual |
|---------|---------------|-------------|--------|
| 1: Fresh → Free Gen | ✅ Anon.* | ✅ F1-F2, F8 | - |
| 2: Upgrade → Purchase | ✅ Anon.3 | ✅ F4 | ✅ StoreKit |
| 3: Pro → Sign Out | ✅ Pro.*, Auth.* | ✅ F3 | - |
| 4: Biometrics | ❌ | ❌ | ✅ Manual |
| 5: Delete Account | ✅ Auth.3 | ❌ | ✅ Manual |
| 6: AI Error → Retry | ✅ AIErr.* | ❌ | - |

---

## Action Items

### 1. Add Missing Logs
- [ ] biometric_service.dart - enable/disable/auth events
- [ ] auth_service.dart - sign in/out/delete events
- [ ] onboarding_screen.dart - started/completed
- [ ] lock_screen.dart - shown/auth events
- [ ] generate_screen.dart - wizard started
- [ ] results_screen.dart - copy/share events
- [ ] home_screen.dart - occasion selected

### 2. Add Log Verification Tests
- [ ] Create `test/services/log_coverage_test.dart`
- [ ] Verify each journey produces expected logs
- [ ] Mock Log service, assert calls

### 3. Add Biometric Journey Tests
- [ ] Golden path: F15 - Biometric enable/disable
- [ ] Golden path: F16 - Lock screen auth
- [ ] Scenario: Biometric.* group
