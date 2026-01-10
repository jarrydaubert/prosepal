# Secret Haiku Generator - Easter Egg Feature

## Overview

A hidden haiku generator accessible by tapping the username 5 times in Settings. Generates haikus in both English and Japanese script. Pro subscription required.

---

## Trigger Mechanism

**Location:** Settings screen → Account section → Username/email display

**Action:** Tap username 5 times within 2 seconds

**Feedback:**
- Taps 1-4: Subtle scale animation (0.98 → 1.0)
- Tap 5: Brief haptic + navigate to HaikuScreen

**Code pattern:**
```dart
int _tapCount = 0;
DateTime? _lastTap;

void _onUsernameTap() {
  final now = DateTime.now();
  if (_lastTap == null || now.difference(_lastTap!) > Duration(seconds: 2)) {
    _tapCount = 0;
  }
  _lastTap = now;
  _tapCount++;
  
  if (_tapCount >= 5) {
    _tapCount = 0;
    context.push('/haiku');
  }
}
```

---

## Screen Design

### Layout

```
┌─────────────────────────────────────┐  Dark background
│  ←                                  │  (Back button, no title)
├─────────────────────────────────────┤
│                                     │
│            🌸                       │  (Cherry blossom or gold accent)
│                                     │
│     "Autumn moonlight—             │  Off-white text
│      a worm digs silently          │
│      into the chestnut."           │
│                        ⎘ Copy      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│     「秋の月光—                     │  Muted text
│      虫が静かに                     │
│      栗の中へ掘る」                 │
│                        ⎘ Copy      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│        [ ✨ New Haiku ]             │  (Coral accent button)
│                                     │
└─────────────────────────────────────┘
```

No usage indicator - clean, minimal interface.

### States

1. **Initial** - Empty state with generate prompt
2. **Loading** - Zen animation (ripple or breathing circle)
3. **Result** - Haiku displayed with copy buttons
4. **Error** - Gentle error message, retry button

---

## Components

### New Components

| Component | Description |
|-----------|-------------|
| `HaikuScreen` | Main secret screen |
| `HaikuCard` | Displays haiku with copy button |
| `ZenLoadingIndicator` | Custom loading animation |

### Reused Components

| Component | Usage |
|-----------|-------|
| `AppButton` | Generate button |
| `UsageIndicator` | Show remaining Pro generations |

---

## Styling

### Color Palette (Dark Zen Theme)

```dart
// Dark, minimal zen aesthetic
static const haikuBackground = Color(0xFF121212);   // Near-black
static const haikuSurface = Color(0xFF1E1E1E);      // Card background
static const haikuAccent = Color(0xFFE57373);       // Brand coral
static const haikuText = Color(0xFFF5F5F5);         // Off-white text
static const haikuTextSecondary = Color(0xFFB0B0B0); // Muted text
static const haikuGold = Color(0xFFD4AF37);         // Accent gold for icon
```

### Typography

```dart
// English haiku - elegant serif feel
static const haikuEnglish = TextStyle(
  fontFamily: 'Georgia',  // Or system serif
  fontSize: 20,
  fontStyle: FontStyle.italic,
  height: 1.8,
  color: haikuText,
);

// Japanese - clean, readable
static const haikuJapanese = TextStyle(
  fontSize: 18,
  height: 1.8,
  color: haikuTextSecondary,
);
```

### Animation

**Loading:** Breathing circle animation
```dart
// Circle scales 1.0 → 1.1 → 1.0 over 2 seconds
// Opacity pulses 0.6 → 1.0 → 0.6
```

**Reveal:** Fade in with slight upward movement
```dart
// Duration: 600ms
// Curve: easeOutCubic
// Translation: 20px → 0px
```

---

## AI Integration

### Prompt Design

```dart
const haikuSystemPrompt = '''
You are a haiku master. Generate a single, original haiku.

Rules:
- Follow 5-7-5 syllable structure
- Include a seasonal reference (kigo) or nature element
- Create a moment of insight or emotion
- Be original, not a famous haiku

Respond in this exact JSON format:
{
  "english": "Line one here\\nLine two here\\nLine three here",
  "japanese": "一行目\\n二行目\\n三行目",
  "season": "autumn"
}
''';
```

### Model

Use same model as main generation (Gemini 2.5 Flash via Firebase AI).

### Response Parsing

```dart
class HaikuResult {
  final String english;
  final String japanese;
  final String season;
}
```

---

## Pro Requirement

### Access Control

- **Check:** `subscriptionService.hasPro` before allowing navigation
- **No Pro = Nothing happens** - 5 taps just do nothing, no indication of hidden feature
- **Usage:** Counts against Pro monthly limit (500) but not displayed on screen

### Trigger Logic

```dart
void _onUsernameTap() {
  final now = DateTime.now();
  if (_lastTap == null || now.difference(_lastTap!) > Duration(seconds: 2)) {
    _tapCount = 0;
  }
  _lastTap = now;
  _tapCount++;
  
  // Only navigate if Pro subscriber
  if (_tapCount >= 5 && subscriptionService.hasPro) {
    _tapCount = 0;
    context.push('/haiku');
  }
}

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `lib/features/settings/haiku_screen.dart` | Main screen |
| `lib/shared/components/haiku_card.dart` | Haiku display card |
| `lib/shared/components/zen_loading.dart` | Loading animation |
| `test/widgets/screens/haiku_screen_test.dart` | Widget tests |

### Modified Files

| File | Changes |
|------|---------|
| `lib/features/settings/settings_screen.dart` | Add tap counter to username |
| `lib/app/router.dart` | Add `/haiku` route |
| `lib/core/services/ai_service.dart` | Add `generateHaiku()` method |
| `lib/core/services/ai_service_test.dart` | Add haiku tests |

---

## Analytics Events

```dart
// Track easter egg discovery
Analytics.logEvent('easter_egg_discovered', {'type': 'haiku'});

// Track haiku generation
Analytics.logEvent('haiku_generated', {'season': result.season});

// Track copy action
Analytics.logEvent('haiku_copied', {'language': 'english' | 'japanese'});
```

---

## Copy Functionality

### English Copy
```
Autumn moonlight—
a worm digs silently
into the chestnut.
```

### Japanese Copy
```
秋の月光—
虫が静かに
栗の中へ掘る
```

### Feedback
- Haptic feedback on copy
- Brief "Copied!" snackbar or checkmark animation

---

## Error Handling

| Error | User Message |
|-------|--------------|
| Network | "The muse needs internet connection" |
| Rate limit | "Too many haikus. Take a breath." |
| AI error | "The muse is resting. Try again." |
| No Pro | Upgrade prompt (see above) |

---

## Test Cases

### Unit Tests
- [ ] `generateHaiku()` returns valid HaikuResult
- [ ] Haiku prompt includes proper format
- [ ] Error handling for malformed AI response

### Widget Tests
- [ ] Tap counter resets after 2 seconds
- [ ] 5 taps navigates to HaikuScreen
- [ ] Non-Pro sees upgrade prompt
- [ ] Copy button copies correct text
- [ ] Loading state shows zen animation
- [ ] Error state shows retry button

### Integration Tests
- [ ] Full flow: tap 5x → generate → copy
- [ ] Usage count decrements after generation

---

## Future Enhancements (Post-Revenue)

- [ ] Free daily haiku for all users
- [ ] Save favorite haikus
- [ ] Share as image (styled card)
- [ ] Seasonal themes (cherry blossoms in spring, etc.)
- [ ] Haiku history
- [ ] Different poetry forms (tanka, senryu)

---

## Implementation Order

1. Add route to router.dart
2. Create HaikuScreen with static placeholder
3. Add tap counter to settings_screen.dart
4. Create AI generateHaiku() method
5. Wire up generation to screen
6. Add copy functionality
7. Add zen loading animation
8. Add error handling
9. Write tests
10. Polish animations

---

## Notes

- Keep it minimal - this is an easter egg, not a full feature
- Don't advertise it anywhere - let users discover it
- Consider adding a small "🌸" indicator after first discovery (optional)
