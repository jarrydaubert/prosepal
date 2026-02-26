# App Store Submission Guide (2025-2026)

> Comprehensive guide for Apple App Store and Google Play Store submission requirements, common rejections, and compliance checklist.

---

## Table of Contents
1. [Apple App Store](#apple-app-store)
   - [Review Process](#review-process)
   - [Key Requirements](#key-requirements)
   - [Common Rejection Reasons](#common-rejection-reasons)
   - [Subscription App Requirements](#subscription-app-requirements)
   - [Privacy Requirements](#privacy-requirements)
2. [Google Play Store](#google-play-store)
   - [Key Requirements](#google-play-key-requirements)
   - [Common Rejection Reasons](#google-play-common-rejections)
   - [2025-2026 Policy Updates](#2025-2026-policy-updates)
3. [Prosepal Compliance Checklist](#prosepal-compliance-checklist)

---

## Apple App Store

### Review Process

Apple reviews apps based on **5 key areas**:
1. **Safety** - User safety, content moderation, child protection
2. **Performance** - Stability, crashes, completeness
3. **Business** - IAP compliance, pricing transparency
4. **Design** - Native iOS experience, Human Interface Guidelines
5. **Legal** - Privacy, data handling, compliance

**Timeline**: 90% of submissions reviewed within 24 hours

**Important**: Every new version requires review, even minor changes.

### Key Requirements

#### SDK Requirements (Effective April 2026)
- iOS/iPadOS apps: Built with iOS 26 SDK or later

#### Account Deletion (Mandatory)
- If app allows account creation, must allow account deletion within the app
- Must be easy to find (not buried in settings)
- Must actually delete data, not just deactivate

#### Privacy Policy
- Must be accessible both in App Store metadata AND within the app
- Must clearly describe all data collection practices
- Required even if app collects minimal data

#### User-Generated Content (If applicable)
- Must have moderation tools ("Report" and "Block" buttons)
- Age-appropriate content filtering
- Content removal mechanisms

### Common Rejection Reasons

#### Immediate Rejections (Blockers)

| Reason | Description | How to Avoid |
|--------|-------------|--------------|
| **Crashes/Bugs** | App crashes during review | Test on clean device, all iOS versions |
| **Incomplete App** | Placeholder content, broken features | Remove all TODO/placeholder content |
| **Missing Privacy Policy** | No policy or hard to find | Link in App Store AND in-app settings |
| **No IAP for Digital Goods** | Using external payment for digital content | Use Apple's StoreKit for all digital purchases |
| **Missing Restore Purchases** | Subscription app without restore button | Implement visible "Restore Purchases" button |
| **Misleading Metadata** | Screenshots/description don't match app | Ensure all screenshots reflect actual app |
| **Private API Usage** | Using undocumented Apple APIs | Only use public APIs |

#### Frequent Rejections

| Reason | Description | How to Avoid |
|--------|-------------|--------------|
| **Performance Issues** | Slow loading, excessive battery drain | Profile and optimize before submission |
| **Broken UI** | Layout issues, unresponsive buttons | Test on all device sizes |
| **Excessive Permissions** | Requesting unnecessary data access | Only request permissions needed for core function |
| **Poor User Experience** | Confusing navigation, unclear purpose | Follow Human Interface Guidelines |
| **Web Wrapper** | App is just a website in a shell | Must provide native iOS experience and value |
| **Copycat App** | Too similar to existing apps | Ensure unique value proposition |
| **Inappropriate Content** | Adult, violent, or offensive content | Review content guidelines thoroughly |

#### 2025 Specific Updates

| New Requirement | Details |
|-----------------|---------|
| **AI Data Sharing** | Must disclose if personal data is shared with AI services (Guideline 5.1.2(i)) |
| **Age Rating Compliance** | Creator apps must implement age restriction mechanisms |
| **Loan App Restrictions** | APR cannot exceed 36%, repayment cannot be required within 60 days |
| **Icon/Brand Protection** | Cannot use another developer's icon, brand, or product name |

### Subscription App Requirements

#### Mandatory Elements

1. **Restore Purchases Button**
   - Must be visible and functional
   - Cannot require user to contact support
   - Must restore without creating new subscription

2. **Pricing Transparency**
   - Display exact price BEFORE purchase
   - Show billing frequency clearly (weekly/monthly/yearly)
   - Show what user gets with subscription
   - Prices must match App Store listing

3. **Subscription Management**
   - Easy access to subscription status
   - Clear cancellation instructions
   - Link to Apple's subscription management

4. **Free Trial Disclosure**
   - Clearly state trial length
   - Explain what happens when trial ends
   - Show price that will be charged

5. **Plan Comparison**
   - Display all subscription tiers together
   - Clear feature comparison
   - Do NOT auto-default to premium tier

#### Subscription UI Best Practices

```
Required Elements on Paywall:
- [ ] Full price displayed (e.g., "$4.99/month")
- [ ] Billing frequency clear
- [ ] What's included in subscription
- [ ] Free trial terms (if applicable)
- [ ] "Restore Purchases" button visible
- [ ] Link to Terms of Service
- [ ] Link to Privacy Policy
- [ ] Cancellation instructions or link
```

### Privacy Requirements

#### Privacy Nutrition Labels

Required disclosures in App Store Connect:

| Category | What to Disclose |
|----------|------------------|
| **Data Used to Track You** | Any data used to track users across apps/websites |
| **Data Linked to You** | Data connected to user identity |
| **Data Not Linked to You** | Anonymous/aggregated data |

#### Data Types to Declare

For Prosepal, likely categories:
- Contact Info (email for auth)
- Identifiers (user ID, device ID)
- Usage Data (app interactions)
- Purchases (subscription status)
- Diagnostics (crash logs)

#### App Tracking Transparency

- Required if linking user data across apps/websites for advertising
- Must use `AppTrackingTransparency` framework
- User must opt-in before tracking

#### Third-Party SDKs (2025 Update)

- Must declare all third-party SDK data collection
- New: Privacy manifests required for SDKs
- New: Signatures required for third-party SDKs

---

## Google Play Store

### Google Play Key Requirements

#### Developer Account Setup
- One-time $25 registration fee
- Complete developer profile with accurate information
- Valid email and working website required

#### Technical Requirements (2025)

| Requirement | Deadline |
|-------------|----------|
| Target API Level 35 (Android 15) | August 31, 2025 |
| Play Billing Library v7+ | August 31, 2025 |
| 16 KB Page Size Compatibility | November 1, 2025 |

#### Privacy Policy
- Mandatory for all apps collecting user data
- Must be accessible from Play Store listing
- Must detail data collection, sharing, and protection measures

#### Data Safety Section
- Similar to Apple's Privacy Labels
- Must declare all data collected and shared
- Must explain data handling practices

### Google Play Common Rejections

#### Policy Violations

| Violation | Description | How to Avoid |
|-----------|-------------|--------------|
| **Restricted Content** | Violence, adult content, hate speech | Review content policy thoroughly |
| **Intellectual Property** | Using copyrighted material without permission | Only use licensed/original content |
| **Impersonation** | Misleading users about app identity | Unique branding, clear developer identity |
| **Privacy Violations** | Mishandling user data | Clear privacy policy, minimal permissions |
| **Deceptive Practices** | Misleading functionality claims | Accurate descriptions and screenshots |
| **Malware/Security** | Suspicious behavior, unsafe links | Security audit before submission |

#### Technical Issues

| Issue | Description | How to Avoid |
|-------|-------------|--------------|
| **Crashes** | App crashes during testing | Thorough QA on multiple devices |
| **Poor Performance** | Slow, laggy, battery drain | Performance profiling |
| **Incomplete App** | Missing features, placeholders | Remove all placeholder content |
| **Device Incompatibility** | Doesn't work on declared devices | Test on variety of devices/API levels |

### 2025-2026 Policy Updates

#### Developer Verification (September 2026)
- **Major Change**: All Android app developers must register with Google
- Initially applies to: Brazil, Indonesia, Singapore, Thailand
- Global expansion planned for 2027+
- Apps from unverified developers may be blocked

#### Enterprise Exemptions
- Fully managed devices: Exempt until September 2027
- Work Profile apps: Exempt until September 2027
- Private apps via Managed Google Play: Permanently exempt

#### Health Data (2025)
- Stricter eligibility for Health Connect access
- Medical apps require additional review
- Must include disclaimers for health information

#### Photo/Video Permissions (2025)
- Must only request media access necessary for core functions
- Audit app manifests for unnecessary permissions

---

## Prosepal Compliance Checklist

### Pre-Submission Checklist

#### App Functionality
- [ ] App launches without crashes
- [ ] All features work as described
- [ ] No placeholder content or TODO items
- [ ] Works on all supported iOS versions
- [ ] Works on all device sizes (iPhone SE to Pro Max)
- [ ] Dark mode support (if applicable)

#### Authentication
- [ ] Sign in with Apple works correctly
- [ ] Google Sign-In works correctly
- [ ] Email/password auth works correctly
- [ ] Account deletion is accessible and functional
- [ ] Password reset flow works

#### Subscriptions (Critical)
- [ ] "Restore Purchases" button visible on paywall
- [ ] Restore actually works (test with sandbox account)
- [ ] All prices displayed clearly
- [ ] Billing frequency shown (weekly/monthly/yearly)
- [ ] Free trial terms clearly stated (if applicable)
- [ ] Subscription benefits listed
- [ ] Terms of Service link accessible
- [ ] Privacy Policy link accessible
- [ ] Cancellation instructions provided

#### Privacy
- [ ] Privacy Policy accessible in-app (Settings)
- [ ] Privacy Policy URL in App Store Connect
- [ ] All data collection accurately declared
- [ ] Third-party SDK data collection declared
- [ ] User consent obtained before data collection

#### Content
- [ ] No offensive content
- [ ] Age rating accurately set
- [ ] AI-generated content disclosed (if applicable)
- [ ] No copyrighted material without license

#### Metadata
- [ ] App name accurate and unique
- [ ] Description matches actual functionality
- [ ] Screenshots show real app screens
- [ ] Keywords relevant and accurate
- [ ] Category appropriate
- [ ] Support URL works
- [ ] Marketing URL works (if provided)

#### Technical
- [ ] Built with latest stable SDK
- [ ] No private API usage
- [ ] No excessive battery/CPU usage
- [ ] Reasonable app size
- [ ] All required capabilities declared in entitlements

### App Store Connect Checklist

#### Required Information
- [ ] App name (30 characters max)
- [ ] Subtitle (30 characters max)
- [ ] Description (4000 characters max)
- [ ] Keywords (100 characters max)
- [ ] Support URL
- [ ] Privacy Policy URL
- [ ] Category selected
- [ ] Age rating questionnaire completed

#### Screenshots Required
| Device | Sizes Needed |
|--------|--------------|
| iPhone 6.9" | 1290 x 2796 or 1320 x 2868 |
| iPhone 6.5" | 1242 x 2688 or 1284 x 2778 |
| iPhone 5.5" | 1242 x 2208 |
| iPad Pro 12.9" | 2048 x 2732 |

#### App Review Information
- [ ] Demo account credentials (if login required)
- [ ] Notes for reviewer explaining any special setup
- [ ] Contact information for reviewer questions

### Google Play Console Checklist

#### Store Listing
- [ ] App title (50 characters max)
- [ ] Short description (80 characters max)
- [ ] Full description (4000 characters max)
- [ ] App icon (512 x 512)
- [ ] Feature graphic (1024 x 500)
- [ ] Screenshots (min 2, max 8)
- [ ] Privacy Policy URL

#### Data Safety
- [ ] All data collection declared
- [ ] Data sharing practices declared
- [ ] Security practices declared
- [ ] Data deletion options declared

#### Content Rating
- [ ] IARC questionnaire completed
- [ ] Appropriate rating assigned

---

## Quick Reference: Top 10 Rejection Reasons

### Apple App Store
1. Crashes and bugs
2. Missing or broken Restore Purchases
3. Incomplete app / placeholder content
4. Privacy policy missing or inaccessible
5. Misleading screenshots/description
6. No account deletion option
7. Using external payments for digital goods
8. Excessive permissions
9. Poor user experience
10. Guideline 2.1 - App Completeness

### Google Play Store
1. Policy violations (content/privacy)
2. Crashes and bugs
3. Intellectual property infringement
4. Misleading metadata
5. Privacy policy issues
6. Deceptive practices
7. Malware/security concerns
8. Incomplete app
9. Device incompatibility
10. Impersonation

---

## Resources

### Apple
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)

### Google
- [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Material Design Guidelines](https://material.io/design)
- [Google Play Billing](https://developer.android.com/google/play/billing)

---

*Last updated: January 2026*
