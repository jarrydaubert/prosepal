# Subscription Testing Guide

> Manual verification checklist for RevenueCat subscription flows

---

## Testing Environments

| Environment | Use Case | Setup Required |
|-------------|----------|----------------|
| **Test Store** | Development, instant purchases | None (default) |
| **Apple Sandbox** | Pre-submission testing | Sandbox tester account |
| **TestFlight** | Production-like testing | TestFlight build |

### Test Store vs Sandbox

Test Store (default during development):
- Instant purchases, no Apple ID needed
- Cannot test real App Store flows
- **Do NOT submit with Test Store enabled**

Apple Sandbox:
- Real App Store simulation
- Requires sandbox tester account in App Store Connect
- Subscription renewals accelerated (1 month = 5 min)

---

## Sandbox Renewal Rates

| Duration | Sandbox Time |
|----------|--------------|
| 3 days | 2 min |
| 1 week | 3 min |
| 1 month | 5 min |
| 2 months | 10 min |
| 3 months | 15 min |
| 6 months | 30 min |
| 1 year | 1 hour |

Max 12 renewals per day in sandbox.

---

## Pre-Launch Checklist

### Code Changes
- [ ] Set `_useTestStore = false` in `subscription_service.dart`
- [ ] Verify iOS API key is set (not Android key)
- [ ] Remove all debug print statements

### RevenueCat Dashboard
- [ ] Products configured and approved
- [ ] Entitlement "pro" linked to products
- [ ] Offering "default" set as current
- [ ] Webhook configured (if using server-side)

### App Store Connect
- [ ] In-App Purchases approved
- [ ] Sandbox tester account created
- [ ] Products "Cleared for Sale"
- [ ] Wait ~24 hours after approval before release

### Manual Testing (Real Device)
- [ ] Fresh install shows free tier
- [ ] Paywall displays correct pricing
- [ ] Purchase completes successfully
- [ ] Pro status updates immediately
- [ ] Unlimited generations work
- [ ] Restore purchases recovers entitlement
- [ ] Reinstall + restore works
- [ ] Transactions appear in RevenueCat dashboard

### App Store Compliance
- [ ] Subscription terms in app description
- [ ] Privacy policy link in app
- [ ] Terms of service link in app
- [ ] Cancel/manage subscription link accessible

---

## Debug Logs

RevenueCat logs are prefixed with `[Purchases]`. Key indicators:

| Emoji | Meaning |
|-------|---------|
| 😻 | Success from RevenueCat |
| 😻💰 | Purchase info received |
| 💰 | Product-related messages |
| ‼️ | Errors requiring attention |
| ⚠️ | Implementation warnings |

Enable debug logs:
```dart
await Purchases.setLogLevel(LogLevel.debug);
```

---

## Automated Tests

Run device-only tests (requires real device/simulator):
```bash
patrol test -t integration_test/device_only/revenuecat_test.dart
```

These tests verify:
- SDK initialization
- Offerings fetch correctly
- Products have valid identifiers and prices
- User identity is assigned
- Restore purchases API works
- Paywall navigation works
- Pro status bypasses upgrade prompts

---

## Troubleshooting

### "No packages available"
- Check RevenueCat dashboard for configured products
- Verify offering is set as "current"
- Wait for App Store product approval

### Purchase fails silently
- Check debug logs for `‼️` errors
- Verify sandbox account is configured
- Try signing out of App Store and back in

### Pro status not updating
- Check `isProProvider` subscription
- Verify entitlement ID matches ("pro")
- Check `CustomerInfo.entitlements.active`

### Restore doesn't find purchases
- Must use same sandbox account
- Purchases may have expired (sandbox renewals)
- Check RevenueCat dashboard for transaction history
