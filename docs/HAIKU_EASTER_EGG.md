# Secret Haiku Generator - Easter Egg Feature

## Overview

A hidden haiku generator accessible by tapping the username 5 times in Settings. Generates haikus in both English and Japanese script. Pro subscription required.

---

## Trigger Mechanism

**Location:** Settings screen → Account section → Username/email display

**Action:** Tap username 5 times within 2 seconds

**Behavior:**
- Taps 1-4: Subtle scale animation (0.98 → 1.0)
- Tap 5 (Pro): Brief haptic + navigate to HaikuScreen
- Tap 5 (No Pro): Nothing happens - no indication of hidden feature

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
│     秋の月光—                       │  Muted text
│     虫が静かに                      │
│     栗の中へ掘る                    │
│                        ⎘ Copy      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│      [ ✨ Generate Haiku ]          │  (Coral accent button)
│                                     │
└─────────────────────────────────────┘
```

No usage indicator - clean, minimal interface.

### States

1. **Initial** - Cherry blossom icon + "Generate Haiku" button
2. **Loading** - Zen breathing circle animation
3. **Result** - Haiku displayed with copy buttons, "New Haiku" button
4. **Error** - Gentle error message, retry button

---

## Components

### New Components

| Component | Description |
|-----------|-------------|
| `HaikuScreen` | Main secret screen |
| `HaikuCard` | Displays haiku with copy button |
| `ZenLoadingIndicator` | Custom breathing circle animation |

### Reused Components

| Component | Usage |
|-----------|-------|
| `AppButton` | Generate button |

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
// English haiku - elegant serif feel (system fonts)
static const haikuEnglish = TextStyle(
  fontFamilyFallback: ['Georgia', 'Times New Roman', 'serif'],
  fontSize: 20,
  fontStyle: FontStyle.italic,
  height: 1.8,
  color: haikuText,
);

// Japanese - ensure CJK support
static const haikuJapanese = TextStyle(
  fontFamilyFallback: ['Hiragino Sans', 'Noto Sans JP', 'sans-serif'],
  fontSize: 18,
  height: 1.8,
  color: haikuTextSecondary,
);
```

### Animation

**Loading:** Breathing circle animation
```dart
// Use AnimationController with TweenSequence
AnimationController(duration: Duration(seconds: 2), vsync: this)
  ..repeat(reverse: true);

// Scale: 1.0 → 1.1 → 1.0
// Opacity: 0.6 → 1.0 → 0.6
```

**Reveal:** Fade in with slight upward movement
```dart
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutCubic,
  )),
  child: FadeTransition(opacity: controller, child: content),
)
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

### Response Model

```dart
// lib/core/models/haiku_result.dart
@freezed
abstract class HaikuResult with _$HaikuResult {
  const factory HaikuResult({
    required String english,
    required String japanese,
    required String season,
  }) = _HaikuResult;

  factory HaikuResult.fromJson(Map<String, dynamic> json) =>
      _$HaikuResultFromJson(json);
}
```

---

## Pro Requirement

### Access Control

- **Check:** `subscriptionService.hasPro` before allowing navigation
- **No Pro = Nothing happens** - 5 taps do nothing, no indication of hidden feature
- **Usage:** Counts against Pro monthly limit (500) but not displayed on screen

### Trigger Logic (in settings_screen.dart)

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
  
  // Only navigate if Pro subscriber - silent fail otherwise
  if (_tapCount >= 5 && subscriptionService.hasPro) {
    _tapCount = 0;
    HapticFeedback.mediumImpact();
    context.push('/haiku');
  }
}
```

### Route Protection (in router.dart)

```dart
GoRoute(
  path: '/haiku',
  redirect: (context, state) {
    final hasPro = ref.read(subscriptionProvider).hasPro;
    return hasPro ? null : '/home'; // Silent redirect if not Pro
  },
  builder: (context, state) => const HaikuScreen(),
),
```

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `lib/features/settings/haiku_screen.dart` | Main screen |
| `lib/core/models/haiku_result.dart` | Freezed response model |
| `lib/shared/components/haiku_card.dart` | Haiku display card |
| `lib/shared/components/zen_loading.dart` | Loading animation |
| `test/widgets/screens/haiku_screen_test.dart` | Widget tests |

### Generated Files (after build_runner)

| File | Purpose |
|------|---------|
| `lib/core/models/haiku_result.freezed.dart` | Freezed generated |
| `lib/core/models/haiku_result.g.dart` | JSON serialization |

### Modified Files

| File | Changes |
|------|---------|
| `lib/features/settings/settings_screen.dart` | Add tap counter to username |
| `lib/app/router.dart` | Add `/haiku` route with Pro guard |
| `lib/core/services/ai_service.dart` | Add `generateHaiku()` method |
| `test/services/ai_service_test.dart` | Add haiku generation tests |

---

## State Management

```dart
// Simple StateNotifier for haiku generation
final haikuProvider = StateNotifierProvider<HaikuNotifier, AsyncValue<HaikuResult?>>(
  (ref) => HaikuNotifier(ref.read(aiServiceProvider)),
);

class HaikuNotifier extends StateNotifier<AsyncValue<HaikuResult?>> {
  HaikuNotifier(this._aiService) : super(const AsyncValue.data(null));
  
  final AiService _aiService;
  
  Future<void> generate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _aiService.generateHaiku());
  }
}
```

---

## Analytics Events

```dart
// Track easter egg discovery
Analytics.logEvent('easter_egg_discovered', {'type': 'haiku'});

// Track haiku generation
Analytics.logEvent('haiku_generated', {'season': result.season});

// Track copy action  
Analytics.logEvent('haiku_copied', {'language': 'english'}); // or 'japanese'
```

---

## Copy Functionality

### English Copy (no formatting marks)
```
Autumn moonlight—
a worm digs silently
into the chestnut.
```

### Japanese Copy (no brackets)
```
秋の月光—
虫が静かに
栗の中へ掘る
```

### Feedback
- Haptic feedback on copy
- Brief "Copied!" snackbar (1.5s auto-dismiss)

---

## Error Handling

| Error | User Message |
|-------|--------------|
| No connection | "Connect to the internet to summon the muse" |
| Rate limit | "Too many haikus. Take a breath." |
| AI error | "The muse is resting. Try again." |
| Malformed JSON | "The muse speaks in riddles. Try again." |

```dart
// In ai_service.dart generateHaiku()
try {
  final json = jsonDecode(response);
  return HaikuResult.fromJson(json);
} on FormatException catch (e) {
  throw AiException(
    type: AiErrorType.unknown,
    userMessage: 'The muse speaks in riddles. Try again.',
  );
}
```

---

## Accessibility

- **Semantic labels:** Copy buttons need `Semantics(label: 'Copy English haiku')`
- **Screen reader:** Haiku text should be readable as prose
- **Focus order:** Generate button → English haiku → Copy → Japanese haiku → Copy

---

## Test Cases

### Unit Tests
- [ ] `generateHaiku()` returns valid HaikuResult
- [ ] Haiku prompt includes proper JSON format instruction
- [ ] Error handling for malformed AI response
- [ ] Error handling for network failure

### Widget Tests
- [ ] Tap counter resets after 2 seconds
- [ ] 5 taps with Pro navigates to HaikuScreen
- [ ] 5 taps without Pro does nothing (silent)
- [ ] Copy button copies correct text
- [ ] Loading state shows zen animation
- [ ] Error state shows retry button
- [ ] Accessibility labels present

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

1. Create `HaikuResult` model + run build_runner
2. Add route to router.dart with Pro guard
3. Create basic HaikuScreen with static placeholder
4. Add tap counter to settings_screen.dart
5. Add `generateHaiku()` to ai_service.dart
6. Create `haikuProvider` StateNotifier
7. Wire up generation to screen
8. Add HaikuCard with copy functionality
9. Add ZenLoadingIndicator animation
10. Add error handling
11. Write tests
12. Polish animations + accessibility

---

## Notes

- Keep it minimal - easter egg, not a full feature
- Don't advertise anywhere - let users discover it
- Silent fail for non-Pro maintains secrecy
