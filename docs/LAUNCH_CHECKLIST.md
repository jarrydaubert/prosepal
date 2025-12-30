# Prosepal Launch Checklist

> Based on [RevenueCat Launch Checklist](https://www.revenuecat.com/docs/test-and-launch/launch-checklist)

---

## 🔴 Critical Pre-Launch

| Item | Status | Notes |
|------|--------|-------|
| **RevenueCat API Key is PRODUCTION (not Test Store)** | ⬜ | Check `lib/core/services/subscription_service.dart` |
| **RevenueCat 'default' offering has packages** | ⬜ | Add weekly/monthly/yearly to default offering |
| **App Store agreements & tax forms signed** | ⬜ | App Store Connect > Agreements |
| **Banking info added** | ⬜ | Required to fetch products |

---

## 1. RevenueCat Plan Limits

| Item | Status | Notes |
|------|--------|-------|
| Understand $2,500 MTR free limit | ⬜ | After limit: 1% of tracked revenue |
| Consider adding credit card early | ⬜ | Prevents losing access to features |

---

## 2. User Identity Testing

| Test | iOS | How to Verify |
|------|-----|---------------|
| App User IDs set correctly | ⬜ | Check RevenueCat dashboard after sign-in |
| Users appear in Activity view | ⬜ | Make test purchase, verify in dashboard |
| No unexpected aliases | ⬜ | Check customer page for each test user |

**Prosepal Implementation:**
```dart
// In subscription_service.dart - identifyUser() links Supabase user ID to RevenueCat
await Purchases.logIn(userId);
```

---

## 3. Purchase Testing

### 3.1 Sandbox Testing (Real Device Required)

| Test | iOS | Steps |
|------|-----|-------|
| All products available | ⬜ | Open paywall, verify 3 packages show |
| Weekly purchase works | ⬜ | Buy weekly, verify pro access |
| Monthly purchase works | ⬜ | Buy monthly, verify pro access |
| Yearly purchase works | ⬜ | Buy yearly, verify pro access |
| Pro content unlocks immediately | ⬜ | After purchase, Generate Messages available |
| Transaction appears in RevenueCat | ⬜ | Check dashboard Activity tab |

### 3.2 Subscription Lifecycle

| Test | iOS | Steps |
|------|-----|-------|
| Active subscription maintains pro access | ⬜ | Return to app while subscription active |
| Expired subscription revokes pro access | ⬜ | Wait for sandbox expiry (~5 min), verify revoked |
| Subscription renewal works | ⬜ | Sandbox auto-renews 6 times max |

### 3.3 Restore Purchases

| Test | iOS | Steps |
|------|-----|-------|
| Restore works after uninstall | ⬜ | Uninstall, reinstall, tap Restore Purchases |
| Restore works after sign-out/sign-in | ⬜ | Sign out, sign in, verify pro status restored |

**Sandbox Subscription Durations:**
| Real Duration | Sandbox Duration |
|---------------|------------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 1 year | 1 hour |

---

## 4. Webhooks & Integrations

| Item | Status | Notes |
|------|--------|-------|
| No webhook failures in RevenueCat | ⬜ | Check Webhooks tab for errors |
| Firebase Analytics receiving events | ⬜ | Verify in Firebase Console |

---

## 5. Prepare Release

### 5.1 App Store Requirements

| Item | Status | Notes |
|------|--------|-------|
| Subscription disclosure in description | ⬜ | Include auto-renewal details |
| App Privacy disclosure updated | ⬜ | App Store Connect > App Privacy |
| IDFA usage disclosed (if using attribution) | ⬜ | App Tracking Transparency |

### 5.2 Release Strategy

| Item | Status | Notes |
|------|--------|-------|
| Phased rollout enabled | ⬜ | Recommended for first release |
| Manual release selected | ⬜ | Wait 24h after "Cleared for Sale" for products |
| Marketing campaign scheduled AFTER 24h | ⬜ | Products need time to propagate |

---

## 6. Prosepal-Specific Tests

### 6.1 Authentication

| Test | iOS | Steps |
|------|-----|-------|
| Apple Sign In works | ⬜ | Real device only |
| Google Sign In works | ⬜ | Verify OAuth flow |
| Email/Password works | ⬜ | Use appreview@prosepal.app |
| Magic Link works | ⬜ | Check email delivery |
| Sign Out works | ⬜ | Verify session cleared |
| Delete Account works | ⬜ | Verify data removed |

### 6.2 Core Features

| Test | iOS | Steps |
|------|-----|-------|
| All 10 occasions selectable | ⬜ | Birthday, Wedding, etc. |
| All relationships selectable | ⬜ | Close Friend, Family, etc. |
| All tones selectable | ⬜ | Heartfelt, Funny, etc. |
| Message generation works | ⬜ | Verify 3 messages returned |
| Copy message works | ⬜ | Verify clipboard |
| Share message works | ⬜ | Verify share sheet |

### 6.3 Free Tier Limits

| Test | iOS | Steps |
|------|-----|-------|
| New user gets 3 free generations | ⬜ | Fresh install |
| Counter decrements correctly | ⬜ | Generate, verify count -1 |
| 0 remaining shows upgrade prompt | ⬜ | Use all 3, verify paywall |
| Pro user has unlimited | ⬜ | After purchase, verify unlimited |

### 6.4 Biometrics (if enabled)

| Test | iOS | Steps |
|------|-----|-------|
| Face ID/Touch ID prompt appears | ⬜ | Enable in Settings |
| Successful auth unlocks app | ⬜ | Use biometric |
| Failed auth shows retry | ⬜ | Cancel biometric |

---

## 7. App Store Review Preparation

| Item | Status | Notes |
|------|--------|-------|
| Test account ready | ⬜ | appreview@prosepal.app / [password] |
| Demo video prepared (optional) | ⬜ | Shows key features |
| Review notes explain subscription | ⬜ | Clear pricing info |
| Privacy Policy URL works | ⬜ | https://prosepal.app/privacy |
| Terms of Service URL works | ⬜ | https://prosepal.app/terms |
| Support URL works | ⬜ | https://prosepal.app/support |

---

## 8. Post-Launch Monitoring

| Item | Frequency | Tool |
|------|-----------|------|
| Crash reports | Daily | Firebase Crashlytics |
| Revenue metrics | Daily | RevenueCat Dashboard |
| User feedback | Daily | App Store Reviews |
| Subscription health | Weekly | RevenueCat Charts |

---

## Quick Reference: RevenueCat Dashboard Links

- **Offerings:** https://app.revenuecat.com/projects/bf963296/product-catalog/offerings
- **Activity:** https://app.revenuecat.com/projects/bf963296/activity
- **Customers:** https://app.revenuecat.com/projects/bf963296/customers
- **API Keys:** https://app.revenuecat.com/projects/bf963296/settings/api-keys

---

## Testing Order (Recommended)

1. ⬜ Fix RevenueCat 'default' offering (add packages)
2. ⬜ Connect real device
3. ⬜ Create Sandbox Apple ID (or use existing)
4. ⬜ Test Apple Sign In
5. ⬜ Verify paywall shows products
6. ⬜ Make sandbox purchase
7. ⬜ Verify pro access
8. ⬜ Test restore purchases
9. ⬜ Test subscription expiry
10. ⬜ Full app walkthrough

---

*Last updated: Dec 2025*
