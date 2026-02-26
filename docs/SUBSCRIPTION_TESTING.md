# Subscription Testing Guide

> Reference for testing RevenueCat subscription flows

---

## Testing Environments

| Environment | Use Case | Notes |
|-------------|----------|-------|
| **Test Store** | Development | Instant purchases, no Apple ID needed |
| **Apple Sandbox** | Pre-submission | Requires sandbox tester account |
| **TestFlight** | Production-like | Real App Store simulation |

### Test Store vs Sandbox

**Test Store** (default during development):
- Instant purchases, no authentication
- Cannot test real App Store flows
- **Never submit with Test Store enabled**

**Apple Sandbox:**
- Real App Store simulation
- Requires sandbox tester in App Store Connect
- Subscription renewals are accelerated

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

## Debug Logs

RevenueCat logs are prefixed with `[Purchases]`:

| Emoji | Meaning |
|-------|---------|
| 😻 | Success |
| 😻💰 | Purchase info received |
| 💰 | Product-related |
| ‼️ | Error (requires attention) |
| ⚠️ | Implementation warning |

Enable debug logs:
```dart
await Purchases.setLogLevel(LogLevel.debug);
```

---

## Troubleshooting

### "No packages available"
- Check RevenueCat dashboard for configured products
- Verify offering is set as "current"
- Wait for App Store product approval (~24 hours)

### Purchase fails silently
- Check debug logs for `‼️` errors
- Verify sandbox account is configured
- Sign out of App Store and back in

### Pro status not updating
- Check `isProProvider` subscription
- Verify entitlement ID matches ("pro")
- Check `CustomerInfo.entitlements.active`

### Restore doesn't find purchases
- Must use same sandbox account
- Purchases may have expired (sandbox renewals)
- Check RevenueCat dashboard for transaction history

---

## Manual Test Checklist

Run these on real device before submission:

1. Fresh install shows free tier
2. Paywall displays correct pricing
3. Purchase completes successfully
4. Pro status updates immediately
5. Unlimited generations work
6. Restore purchases recovers entitlement
7. Reinstall + restore works
8. Transactions appear in RevenueCat dashboard
