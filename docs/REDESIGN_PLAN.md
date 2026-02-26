# Prosepal Redesign Plan

> **Status:** ✅ APPROVED FOR BUILD  
> **Last Updated:** 2026-01-24  
> **Reviewed By:** Grok, Claude, ChatGPT, Gemini (3 rounds + stress tests)  
> **Verdict:** All 4 reviewers say GO  
> **Preview:** `prosepal-mobile-preview/public/index.html` | `prosepal-web-preview/public/index.html`

---

## Pre-Build Blockers (Must resolve before coding)

| # | Blocker | Resolution | Owner | Source |
|---|---------|------------|-------|--------|
| 1 | **Analytics pipeline missing** | Implement Firebase Analytics (not just Crashlytics logs) for queryable rollout data | Eng | ChatGPT R3 |
| 2 | **Chat transcript privacy** | Define retention/deletion policy, add "Clear draft" affordance | PM/Eng | ChatGPT R3 |
| 3 | **Data migration crash risk** | Check for old `form_restoration_generate` key on startup, clear or migrate | Eng | Gemini R3 |
| 4 | **History data adapter** | Create adapter to read legacy Result format - don't wipe user history | Eng | Gemini R3 |
| 5 | **Gold CTA contrast FAILS** | White on #FBBF24 = **2.8:1** (needs 4.5:1). Use dark text or darker gold | Design | CRO Analysis |
| 6 | **Paywall frequency capping** | Add 24h cooldown after explicit dismiss | Eng | CRO Analysis |
| 7 | **Error states UX** | Design 3 error buckets (offline, retryable, non-retryable) | Design | ChatGPT R3 |
| 8 | **"Something Else" bottom sheet** | Design the browsable occasion list UI (not just "figure out while coding") | Design | Gemini Stress |
| 9 | **Default tone for skippers** | If user skips tone, default to `Tone.heartfelt` implicitly | Eng | Claude Stress |
| 10 | **ChatSession JSON schema** | Define fields, types, nullability before coding | Eng | Gemini Stress |

### Resolved Blockers (from earlier rounds)

| Blocker | Resolution |
|---------|------------|
| Session persistence | ✅ Schema defined (see below) |
| Analytics taxonomy | ✅ Events defined (see below) |
| Destructive editing | ✅ Grey out + preserve text, no confirmation dialog (Claude R3) |
| Paywall trigger | ✅ Documented (value-first, same as current) |
| Zero state | ✅ Designed (starter chips) |

---

## Round 3 Consensus: Scope Changes

Based on final reviewer feedback:

| Item | Original Plan | Revised | Source |
|------|---------------|---------|--------|
| **History search** | CUT | **KEEP** (already built, costs nothing) | Claude R3 |
| **Confirmation dialog for editing** | ADD | **CUT** (over-engineered, adds friction) | Claude R3 |
| **Result card labels** | ADD ("Warm & personal") | **CUT for v1** (keep "Option 1, 2, 3") | Claude R3 |
| **Error UX types** | 7 distinct | **3 buckets** (offline, retryable, non-retryable) | ChatGPT R3 |
| **Gold usage** | Tertiary throughout | **Pro badge + Pay button ONLY** (avoid Lakers aesthetic) | Gemini R3 |

---

## Behaviors to Preserve

These current behaviors must be maintained in the redesign:

| Behavior | Current Location | Action |
|----------|------------------|--------|
| **Confetti celebration** | `results_screen.dart` (first-ever copy) | **KEEP** - delightful moment |
| **App Store review prompt** | `results_screen.dart` (after copy) | **KEEP** - preserve in `draft_copied` handler + add cooldown (ChatGPT Stress) |
| **Free usage counter** | Home screen header | **ADAPT** - add pill in chat AppBar: "2 free messages left" |
| **Pro badge tappability** | Home header → subscription mgmt | **KEEP** - same behavior |
| **Paywall cancellation** | N/A | **ADD** - cancel delayed paywall if user starts refine/edit within 3s |
| **"Something else..." list** | N/A | **ADD** - must open browsable occasion list (replace grid scanability) |

---

## Features Being Removed

| Feature | Why | Impact |
|---------|-----|--------|
| **Occasion Grid** | Replaced by chat chips | Loss of visual scanability - mitigate with "Something else..." list |
| **Step Indicator** | Chat is the progress | Loss of explicit progress - mitigate with visible selections |
| **"Continue" Button** | Chips auto-advance | Loss of explicit gating |
| **Save to Calendar** | Scope cut | Check usage data - if >5% use it, reconsider |
| **Birthday Card Pulse** | No grid | First-run affordance moves to zero state |
| **Message Length Selector** | Not in plan | **ADD BACK** to details input or chat flow |

---

## Current vs Planned: Executive Summary

| Aspect | Current Implementation | Planned (v2) |
|--------|----------------------|--------------|
| **Theme** | Dark only ("Spotlight Cinematic") | Light + Dark (Material 3, system-follows) |
| **Primary Color** | Gold/Amber (#FBBF24) | Purple (#7C5DCA), gold ONLY for Pro/Pay |
| **Background** | Near-black (#050505) | Light (#FFFBFF) or dark (auto-generated) |
| **UX Pattern** | 3-step wizard (Relationship → Tone → Details) | Conversational chat with chips |
| **Navigation** | Back button to previous step | Tap any previous bubble to edit (no confirmation) |
| **Generation Trigger** | Must complete all 3 steps | Occasion + Relationship = can generate |
| **Occasions Display** | Grid of 40+ cards with search | Chat chips + "Something else..." browsable list |

---

## Blocker Resolutions

### 1. Analytics Pipeline (NEW - ChatGPT R3)

**Current:** `Log.info()` → Crashlytics (not queryable for rollout decisions)

**Required:** Implement Firebase Analytics or similar

```dart
// Dual-write: Crashlytics for debugging + Analytics for metrics
class AnalyticsService {
  void track(String event, Map<String, dynamic> params) {
    Log.info(event, params);  // Crashlytics
    FirebaseAnalytics.instance.logEvent(name: event, parameters: params);  // Analytics
  }
}
```

### 2. Chat Transcript Privacy (NEW - ChatGPT R3)

**Issue:** Storing full `chatMessages` = PII risk (names, sensitive situations)

**Resolution:**
- Add "device only" disclaimer (like History)
- Add "Clear draft" button in chat
- Define retention: 24h auto-expire (same as current)
- Document: iCloud/Google backup may include local storage

### 3. Data Migration (NEW - Gemini R3)

**Issue:** Old `form_restoration_generate` JSON → new chat format = crash risk

**Resolution in `main.dart`:**
```dart
// On startup, before any storage access:
final prefs = await SharedPreferences.getInstance();
if (prefs.containsKey('form_restoration_generate')) {
  // Old format - clear it to prevent parsing errors
  await prefs.remove('form_restoration_generate');
  Log.info('Cleared legacy form restoration data');
}
```

### 4. History Data Adapter (NEW - Gemini R3)

**Issue:** Current History = list of `Result` objects. New = list of `ChatSession`.

**Resolution:**
```dart
class HistoryAdapter {
  // Read legacy format and display in new UI
  List<HistoryItem> loadHistory() {
    final legacy = loadLegacyResults();  // Old format
    final modern = loadChatSessions();   // New format
    return [...legacy.map(adaptLegacy), ...modern];
  }
  
  HistoryItem adaptLegacy(Result r) => HistoryItem(
    // Map old fields to new structure
  );
}
```

### 5. Gold CTA Contrast (UPDATED - CRO Analysis)

**Issue:** White text on #FBBF24 = **2.8:1 contrast** (FAILS WCAG 4.5:1)

**Options:**
| Option | Contrast | Recommendation |
|--------|----------|----------------|
| Dark text (#1C1B1F) on #FBBF24 | ~10:1 | ✅ **Use this** |
| White text on darker gold (#C4960A) | ~4.5:1 | Acceptable |
| Gold border + purple fill + white text | ~12:1 | Also works |

**Decision:** Use **dark text on gold** for CTA buttons.

### 6. Paywall Frequency Capping (NEW - CRO Analysis)

**Issue:** No cooldown after dismiss - could over-show and annoy

**Resolution:**
```dart
// After explicit dismiss (not purchase):
await prefs.setString('paywall_last_dismissed', DateTime.now().toIso8601String());

// Before showing paywall:
final lastDismissed = prefs.getString('paywall_last_dismissed');
if (lastDismissed != null) {
  final elapsed = DateTime.now().difference(DateTime.parse(lastDismissed));
  if (elapsed < Duration(hours: 24)) {
    return;  // Don't show - cooldown active
  }
}
```

**Exception:** Always show when user explicitly taps "Upgrade".

### 7. Error States UX (SIMPLIFIED - ChatGPT R3)

**3 Buckets Only:**

| Bucket | Scenarios | UX |
|--------|-----------|-----|
| **Offline** | Network failure | Banner at top: "You're offline" + disable Generate |
| **Retryable** | Timeout, model error, parse error, truncation | Inline bubble: "That didn't work. [Try again]" |
| **Non-retryable** | Rate limit, content blocked, safety | Inline bubble: "You've hit the limit. [Upgrade]" or "I can't help with that." |

Error bubbles **do not auto-dismiss** - they stay until user acts or succeeds.

---

## V1 Scope (Final)

| Feature | Current | v1 Decision | Source |
|---------|---------|-------------|--------|
| Summary pills | N/A | **CUT** | All |
| History search | ✓ Exists | **KEEP** | Claude R3 |
| History tags | ✓ Exists | **KEEP** | All |
| Saved filter | ✗ New | **ADD** (requires Save button + `isSaved` flag) | All |
| Refinement chips | ✗ New | **ADD** (stateless only) | All |
| Result labels | ✗ New | **CUT for v1** (keep "Option 1, 2, 3") | Claude R3 |
| Confirmation dialog | ✗ New | **CUT** (just grey out, no modal) | Claude R3 |
| Message length selector | ✓ Exists | **KEEP** (add to details flow) | Analysis |
| Animated web hero | ✗ Static | **KEEP STATIC** | All |
| Haptics | ✗ None | **DEFER** | All |
| Smart input parsing | ✗ None | **DEFER** | All |

---

## Implementation Phases (Final)

### Phase 0: Foundation
- [ ] **Analytics pipeline** - Implement Firebase Analytics dual-write
- [ ] **Auth flow analytics** - Add `auth_started`, `auth_method_selected`, `auth_completed`, `auth_error_shown` events
- [ ] **Chat privacy policy** - Document retention, add "Clear draft"
- [ ] **Data migration handler** - Clear old `form_restoration_generate` key
- [ ] **History adapter** - Read legacy format without wiping data
- [ ] **Gold contrast fix** - Dark text on gold CTA
- [ ] **Paywall frequency capping** - 24h cooldown after dismiss
- [ ] **Error UX patterns** - 3 buckets defined

### Phase 1: Ugly Prototype
- [ ] Chat state machine (Cubit/Bloc) - standalone, unit tested
- [ ] **State machine invariants:** free-text never deleted, Generate eligibility monotonic, kill/resume always valid
- [ ] **Rapid tap debounce** - disable chips ~300ms after selection (Claude Stress)
- [ ] **Default tone** - if skipped, use `Tone.heartfelt` implicitly (Claude Stress)
- [ ] Verify: chip flow, "Generate Now" timing, edit behavior (no confirmation)
- [ ] Basic components (unstyled) - ChatBubble, ChipSelector
- [ ] **ChipSelector = horizontal ListView** (never Wrap) for small screens (Gemini Stress)
- [ ] **Chat list with `reversed: true`** for keyboard handling (Gemini Stress)
- [ ] **Save button + `isSaved` flag** - needed for Saved filter
- [ ] **Paywall interruption logic** - cancel if user acts within 3s
- [ ] **"Something Else" bottom sheet** - modal with searchable occasion list
- [ ] **Validate flow feels fast before proceeding**

### Phase 2: Theme
- [ ] `ColorScheme.fromSeed()` with #7C5DCA (light + dark)
- [ ] Gold as tertiary - **Pro badge + Pay button ONLY**
- [ ] Dark text on gold CTA buttons
- [ ] Validate all contrast ratios (including gold on elevated dark surfaces)
- [ ] `ThemeMode.system` support
- [ ] **Accessibility spot-checks** (don't wait for Phase 5):
  - [ ] Test ChipSelector with VoiceOver immediately after building
  - [ ] Test ChatBubble with TalkBack immediately after building
  - [ ] Verify theme switch mid-session doesn't break layouts

### Phase 3: Screen Updates
- [ ] Wire state machine into Home
- [ ] Zero state with starter chips
- [ ] **Returning user detection** - skip starter chips if `total_generations > 0`
- [ ] "Something else..." → browsable occasion list (bottom sheet with search)
- [ ] **Free usage counter starts as shimmer** until server sync completes (Gemini Stress)
- [ ] Error bubbles (3 buckets)
- [ ] **Collapse/de-emphasize error bubbles** after successful retry (ChatGPT Stress)
- [ ] **Auto-retry generation** on connectivity restore (Gemini Stress)
- [ ] Session restore + "Restored your session" snackbar
- [ ] **Session restore option:** "Continue where you left off? [Continue] [Start fresh]" (Claude Stress)
- [ ] Results → Keep "Option 1, 2, 3" + refinement chips
- [ ] History → Keep search + tags + add Saved filter
- [ ] **History lazy loading** - `ListView.builder`, consider "Load more" after 50 items
- [ ] Paywall → Dark text on gold CTA
- [ ] Preserve confetti + App Store review prompt
- [ ] **App Store review cooldown** - don't fire too frequently (like paywall 24h)
- [ ] Message length selector in details
- [ ] **Track `time_to_first_draft`** (P50 AND P95) for 45s threshold metric

### Phase 4: Web Landing Page
- [ ] M3 purple theme (light)
- [ ] Static hero
- [ ] Dark text on gold CTAs

### Phase 5: Polish & QA
- [ ] 60fps animations
- [ ] Accessibility audit (see checklist)
- [ ] **Stress Tests (from all reviewers):**
  - [ ] Migration torture: multiple prior versions, corrupted JSON, 0/1/100+ history
  - [ ] Chat interruption: background mid-chat, reopen after 5min/4hr/24hr
  - [ ] Rapid tapper: 3 chips in 500ms
  - [ ] Keyboard trampoline: test on iOS specifically
  - [ ] Small phone + huge font: iPhone SE + 200% Dynamic Type
  - [ ] Offline generation: banner before tap, auto-retry on reconnect
  - [ ] Paywall race: copy→refine in <3s, copy→background→foreground
  - [ ] History explosion: 500 entries, verify scroll performance
- [ ] **Go/No-Go Checklist (before 10% flag):**
  - [ ] Migration tests pass (no crash, no history loss)
  - [ ] Analytics events visible and match rollout metrics
  - [ ] Paywall delay cancellation is race-safe
  - [ ] Dark-mode gold contrast validated on real devices
  - [ ] State machine invariants cover edit/restore paths
- [ ] Staged rollout: 10% → 25% → 50% → 100%
- [ ] **Minimum 48h per stage**
- [ ] **Update web/App Store assets AFTER approval** (not before)

---

## Key Metrics & Activation

### Activation Definition (CRO Audit)

**Activation = `first_message_copied`**

This is the moment a user "gets it" - they've generated a message AND found it valuable enough to copy. Track this as the primary success metric.

### Analytics Events (Updated)

**Core Flow Events:**

| Event | Properties | When Fired |
|-------|------------|------------|
| `session_start` | `source`, `is_returning` | App opened |
| `occasion_selected` | `occasion_id`, `method` (chip/typed) | Occasion chosen |
| `relationship_selected` | `relationship_id`, `method` | Relationship chosen |
| `tone_selected` | `tone_id` | Tone chosen (optional) |
| `generate_tapped` | `fields_completed` (2-5) | Generate button pressed |
| `draft_received` | `latency_ms`, `word_count` | First draft shown |
| **`time_to_first_draft`** | **`duration_ms`** | **From session_start to draft_received** |
| `draft_copied` | `draft_index`, `is_first_ever` | Copy button pressed |
| `draft_shared` | `draft_index`, `share_target` | Share completed |
| `refine_tapped` | `refine_type` | Refinement chip pressed |
| `regenerate_tapped` | `attempt_number` | Try again pressed |
| `paywall_shown` | `trigger_source` | Paywall displayed |
| `purchase_completed` | `product_id`, `price` | Subscription purchased |

**Auth Events (Signup CRO Audit):**

| Event | Properties | When Fired |
|-------|------------|------------|
| `auth_started` | `source` (paywall/settings/etc) | Auth screen opened |
| `auth_method_selected` | `method` (apple/google/email) | User taps auth button |
| `auth_completed` | `method`, `is_new_user` | Successful sign-in |
| `auth_error_shown` | `error_type`, `method` | Auth error displayed |

---

## Risks to Track

| Risk | Source | Metric | Hold Threshold |
|------|--------|--------|----------------|
| Chat feels slower | Grok, ChatGPT | `time_to_first_draft` | >45s |
| Skip tone → bad output | Claude | Regeneration rate | >40% |
| Edit/restore bugs | ChatGPT | User complaints, content loss | Any reports |
| Lakers aesthetic | Gemini | Visual feedback | Negative comments |
| Migration crashes | Gemini | Crash rate on update | >1% |
| Low activation | CRO Audit | `first_message_copied` rate | <50% of first sessions |
| **Activation drop** | ChatGPT Stress | `first_message_copied` relative delta | **>10% drop vs control = HOLD** |

**Critical Rule (ChatGPT Stress):** If activation (`first_message_copied`) drops >10% relative to control (wizard cohort), HOLD regardless of other metrics passing. Activation is the primary success metric.

---

## Accessibility Checklist

| Check | Current | Target | Status |
|-------|---------|--------|--------|
| Gold CTA text | White (2.8:1) | Dark (10:1) | ⚠️ Fix in Phase 2 |
| Text on primary | 21:1 | ≥ 4.5:1 | ✅ |
| Tap targets | 44x44 | ≥ 44x44 | ✅ |
| Dynamic type | Partial | 200% | Test |
| Reduced motion | Supported | Respected | ✅ |
| Screen reader | Semantics | Full flow | Test |

---

## Paywall CRO Status

**Current strengths (keep):**
- ✅ Value-first trigger (after first copy)
- ✅ Context-aware subtitle
- ✅ Weekly price breakdown
- ✅ Easy dismiss (no guilt-trip)
- ✅ Restore without login

**Gaps to address:**

| Gap | Priority | When |
|-----|----------|------|
| Frequency capping (24h cooldown) | **HIGH** | Phase 0 |
| Gold CTA contrast | **HIGH** | Phase 2 |
| Social proof ("Join 1,000+ Pro users") | Low | v1.1 |
| Trial experiment (3-day free) | Medium | v1.1 |

---

## Auth Flow CRO Status

**Current strengths (8/10 - keep as-is for v1):**
- ✅ Social auth prominent (Apple first on iOS, Google second)
- ✅ Minimal required fields (email only or OAuth)
- ✅ Password visibility toggle
- ✅ Magic link (passwordless) option
- ✅ Mobile-friendly tap targets (56px)
- ✅ Inline validation
- ✅ Proper keyboard type (emailAddress)
- ✅ Terms/Privacy links present
- ✅ Good error handling (AuthErrorHandler)

**Gaps to address:**

| Gap | Priority | When |
|-----|----------|------|
| Auth analytics events | **HIGH** | Phase 0 |
| Email typo detection | Medium | v1.1 |
| Password requirements upfront | Low | v1.1 |
| Error dismiss timing (6s → 4s) | Low | v1.1 |
| Social proof near auth | Low | v1.1 |

---

## Post-V1 Roadmap (v1.1)

| Feature | Priority | Notes |
|---------|----------|-------|
| Summary pills | Medium | If users struggle to scroll back |
| Descriptive result labels | Medium | "Warm & personal" etc. |
| Smart input parsing | High | "Birthday for John" → skip steps |
| Animated web hero | Low | Once conversion baseline known |
| Contextual refinement | Medium | "Make it shorter" with memory |
| Haptic feedback | Low | Polish |
| Social proof on paywall | Low | Once you have user count |
| Free trial experiment | Medium | A/B test |
| **Stalled user email** | Medium | "Started chat, no generation in 48h" → re-engagement email |
| **Onboarding A/B test** | Medium | Current 3-slide vs "dive straight in" |
| **Multi-channel triggers** | Low | Incomplete session email (24h), activation celebration email |
| **Email typo detection** | Medium | "Did you mean gmail.com?" for gmial.com, gmal.com, etc. |
| **Password requirements upfront** | Low | Show Supabase password rules before user types |
| **Auth error dismiss timing** | Low | Reduce from 6s to 4s or dismiss on tap |
| **RTL language support** | Medium | Confirmed as v1.1 deferral |
| **Tablet layout** | Medium | Confirmed as v1.1 deferral |
| **Manual theme override** | Low | User wants light mode but device is dark |
| **iCloud/Android backup exclusion** | Low | Settings toggle for "Exclude from backups" |
| **Session restore dismiss option** | Low | If "Continue / Start fresh" proves valuable |

---

## Reviewer Verdicts (Round 3 + Stress Tests)

| Reviewer | Verdict | Key Contribution (R3) | Stress Test Focus |
|----------|---------|----------------------|-------------------|
| **Grok** | ✅ GO | Confirm minor behaviors (confetti, etc.) | Migration torture, accessibility, "Something Else" regression |
| **Claude** | ✅ GO | Keep History search, cut dialog + labels | Rapid tapper, interrupted user, tone skipper, feature flag split |
| **ChatGPT** | ✅ GO | Analytics pipeline, chat privacy, error buckets | Migration invariants, paywall races, analytics integrity, latency P50/P95 |
| **Gemini** | ✅ GO | Data migration, history adapter, Lakers warning | Small phone + huge font, keyboard, network flakiness, ghost quota |

**All 4 reviewers approved after Round 3 + Stress Tests.**

---

## Technical Implementation Notes (From Stress Tests)

### Chat List (Keyboard Handling)
```dart
// Use reversed ListView to anchor items at bottom
// Handles keyboard expansion naturally
ListView.builder(
  reverse: true,
  itemCount: messages.length,
  itemBuilder: (context, index) => ChatBubble(messages[index]),
)
```

### ChipSelector (Small Screen Safety)
```dart
// NEVER use Wrap - chips push content off-screen on small phones
// ALWAYS use horizontal scroll
SizedBox(
  height: 48,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: chips.map((c) => Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChipWidget(c),
    )).toList(),
  ),
)
```

### Usage Counter (No Bait-and-Switch)
```dart
// Start with shimmer, not default value
Widget buildUsageCounter() {
  if (!usageSynced) {
    return ShimmerPlaceholder(width: 80);  // NOT "3 free left"
  }
  return Text('$remaining free left');
}
```

### Connectivity Auto-Retry
```dart
// Listen to connectivity changes
Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none && hasPendingGeneration) {
    retryPendingGeneration();  // Don't force user to tap "Try again"
  }
});
```

### Default Tone for Skippers
```dart
// In generate handler:
final effectiveTone = selectedTone ?? Tone.heartfelt;  // Implicit default
```

### Rapid Tap Debounce
```dart
// Disable chips briefly after selection
void onChipSelected(Chip chip) {
  if (_debouncing) return;
  _debouncing = true;
  
  handleSelection(chip);
  
  Future.delayed(Duration(milliseconds: 300), () {
    _debouncing = false;
  });
}
```

---

## Quick Reference: What's Lost vs Kept

### Lost (intentionally)
- Occasion grid (→ chat chips)
- Step indicator (→ conversation)
- "Continue" gating (→ auto-advance)
- Save to Calendar (scope cut)
- Birthday pulse animation (no grid)

### Lost (add back)
- Message length selector → **ADD to details**

### Kept
- History search ✅
- History tags ✅
- Confetti celebration ✅
- App Store review prompt ✅
- Pro badge tap behavior ✅
- Paywall triggers (value-first) ✅
- SelectableText ✅
- Copy/Share/Regenerate ✅

### New
- Chat interface
- Starter chips (zero state) - **skip for returning users**
- "Something else..." browsable list
- Refinement chips (stateless)
- Saved filter in History
- Usage counter in chat AppBar
- Error bubbles (3 types)
- Light mode + system preference
- Paywall frequency capping
- `time_to_first_draft` tracking
- Activation metric (`first_message_copied`)
