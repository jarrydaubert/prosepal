---
name: tdd
description: "When the user wants to practice test-driven development, write tests first, or follow a red-green-refactor workflow. Also use when the user mentions 'TDD,' 'test first,' 'red green refactor,' 'write the test first,' or 'test-driven.'"
metadata:
  version: "1.0"
  origin: mattpocock-adapted
---

# Test-Driven Development

You are an expert in TDD for Flutter/Dart. Your goal is to write failing tests first, then make them pass with the simplest implementation, then refactor.

## The TDD Cycle

### 1. Red — Write a Failing Test
- Write the test BEFORE any implementation
- Test should express the desired behavior, not implementation details
- Run it — confirm it fails for the right reason

### 2. Green — Make It Pass
- Write the MINIMUM code to make the test pass
- Don't optimize, don't add extras
- Resist the urge to write "good" code — just make it green

### 3. Refactor — Clean Up
- Now improve the code with the safety net of passing tests
- Extract methods, rename, simplify
- Run tests again — still green?

### Repeat

Each cycle should take 5-15 minutes. If it's taking longer, the step is too big.

## Flutter TDD Patterns

### Unit Tests (Services, Models)

```dart
// test/core/services/ai_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiService', () {
    test('generates message for given occasion', () {
      // Arrange
      final service = AiService(mockClient);

      // Act
      final result = await service.generateMessage(
        occasion: 'birthday',
        relationship: 'friend',
        tone: 'warm',
      );

      // Assert
      expect(result, isNotEmpty);
    });
  });
}
```

### Widget Tests

```dart
// test/features/message/message_screen_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows generate button when form is complete', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [/* mock providers */],
        child: MaterialApp(home: MessageScreen()),
      ),
    );

    // Fill form
    await tester.tap(find.text('Birthday'));
    await tester.pump();

    // Verify
    expect(find.text('Generate Message'), findsOneWidget);
  });
}
```

### Provider Tests (Riverpod)

```dart
// test/providers/message_provider_test.dart
import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message provider starts empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(messageProvider);
    expect(state, isNull);
  });
}
```

## TDD Rules

1. **Never write production code without a failing test first**
2. **Only write enough test to fail** — one assertion at a time
3. **Only write enough code to pass** — no speculative features
4. **Refactor only when green** — never change tests and code simultaneously
5. **Test behavior, not implementation** — tests survive refactors

## When NOT to TDD

- Generated code (freezed, json_serializable)
- Pure UI layout with no logic
- Spike/exploration code (write tests after)
- Third-party SDK wrappers with no business logic

## Commands

```bash
flutter test                           # Run all tests
flutter test test/core/services/       # Run specific directory
flutter test --name "generates message" # Run by test name
flutter test --coverage                # Coverage report
```

## Prosepal Context

### Test Infrastructure
- Tests live in `test/` mirroring `lib/` structure
- See `docs/DEVOPS.md` for the full test pyramid and validation flow
- See `docs/DEVOPS.md` for Supabase-specific verification patterns
- Flake detection: `./scripts/test_flake_audit.sh`

### What to TDD in Prosepal
- **AI service logic** — Prompt construction, response parsing, error handling
- **Subscription logic** — Entitlement checks, free message counting, paywall triggers
- **Message generation flow** — Occasion → relationship → tone → generate pipeline
- **Auth flows** — Login, signup, restore, account deletion state transitions

### What to Skip TDD For
- Firebase AI API calls (mock the boundary)
- RevenueCat SDK calls (mock the boundary)
- Supabase client calls (mock the boundary)
- Theme/styling changes

### Key Test Files
- `test/` — Root test directory
- `integration_test/` — Integration/E2E tests
- Provider tests use `ProviderContainer` with overrides
- Mock external services at the boundary (ai_service, subscription_service, auth)

### Definition of Done
Every TDD cycle must end with:
- `flutter test` passing
- `flutter analyze` clean
- No skipped tests (fix or delete, don't skip)
