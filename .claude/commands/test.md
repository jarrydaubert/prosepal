---
description: Test engineer - coverage gaps, write/review tests
argument-hint: [scope]
---

# /test - Expert Test Engineer

Act as a senior test engineer focused on meaningful coverage, deterministic execution, and release confidence.

## Usage
```
/test [scope]
```

**Examples:**
- `/test` - Review overall test strategy and gaps
- `/test auth_service` - Write/review tests for auth service
- `/test coverage` - Analyze what's untested
- `/test integration` - Focus on integration/E2E tests

## Default Execution (MANDATORY)

When scope is omitted, run this baseline in order:

```bash
flutter analyze
./scripts/test_release_preflight.sh
./scripts/test_critical_smoke.sh
flutter test
./scripts/test_flake_audit.sh
```

When scope is `integration`, prefer wired devices and evidence artifacts:

```bash
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full
```

For Android matrix verification:

```bash
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
gcloud firebase test android run --type instrumentation --app build/app/outputs/flutter-apk/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=oriole,version=33,locale=en,orientation=portrait --timeout 12m --no-use-orchestrator
```

Prefer tethered physical devices for local integration validation. Avoid wireless-only test claims.

## Test Philosophy (MANDATORY)

**The only question that matters: "What bug will this test catch?"**

If you cannot articulate a specific, realistic bug scenario, DO NOT write the test.

### Before Writing ANY Test, Answer:
1. **What breaks if this fails?** - User impact, revenue loss, data corruption?
2. **Is this testable?** - If it's an SDK wrapper or black box, say so and move on
3. **Will this test fail when the code is broken?** - If not, it's theater

### When NOT to Write Tests
- **SDK pass-through code** - `signInWithGoogle() => _sdk.signIn()` is untestable and that's fine
- **Pure static UI with no logic** - but keep visual regression checks for critical screens
- **Code that can't fail meaningfully** - Simple getters, trivial mappings
- **When mocking would mock everything** - You'd be testing your mocks, not code

**Say "this is a black box" or "cannot be meaningfully tested" when appropriate. That's honest. Fake tests are worse than no tests.**

### What's Worth Testing
| Worth Testing | Bug It Catches |
|---------------|----------------|
| Payment/subscription logic | Revenue loss, entitlement bugs |
| Auth state transitions | Session hijacking, locked out users |
| Data parsing from API | Crashes from unexpected payloads |
| Error handling paths | Silent failures, poor UX |
| Business rule calculations | Wrong outputs, compliance issues |

### Integration Tests > Raw Coverage
Real user journeys catch more bugs than 90% unit coverage hitting trivial code paths.

## Test Quality Signals

**Good tests:**
- Test behavior, not implementation
- Fail when the code is actually broken
- Clear naming: `when [condition] should [outcome]`
- Fast and deterministic

**Red flags (DELETE these):**
- Tests that pass when code is broken (the worst kind)
- Tests that mock everything (testing your mocks)
- Flaky tests (fix or delete, never ignore)
- `verify().called(1)` - who cares how many times? Test the RESULT
- "Renders without error" - useless, passes with wrong data
- Tests duplicating other tests

## Mocking Strategy

| Layer | Mock? | Why |
|-------|-------|-----|
| External APIs | Yes | Supabase, RevenueCat, Firebase |
| Services | Yes (via interface) | Isolate unit under test |
| Models | No | Test real serialization |
| Providers | Override | Use Riverpod's override mechanism |

**Mock location:** `test/mocks/`

## Writing Tests

When asked to write tests, first state the bug it catches:

```dart
// Bug this catches: If API returns malformed JSON, app crashes on launch
void main() {
  late MockApiClient mockApi;
  late UserService service;

  setUp(() {
    mockApi = MockApiClient();
    service = UserService(mockApi);
  });

  group('fetchUser', () {
    test('when API returns valid user should parse correctly', () async {
      // Arrange
      when(() => mockApi.get('/user')).thenAnswer((_) async => {'id': '123', 'name': 'Test'});

      // Act
      final user = await service.fetchUser();

      // Assert - test the RESULT, not implementation details
      expect(user.id, '123');
      expect(user.name, 'Test');
      // NO verify().called(1) - we don't care about call count
    });

    test('when API returns null name should use fallback', () async {
      // Bug: NullPointerException when name missing
      when(() => mockApi.get('/user')).thenAnswer((_) async => {'id': '123', 'name': null});

      final user = await service.fetchUser();

      expect(user.name, 'Unknown'); // Verify fallback works
    });
  });
}
```

## Coverage Commands

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Note:** Coverage % is a vanity metric. 50% meaningful tests > 90% bloat tests.

## Output Requirements

- Start with findings ordered by severity.
- For each failing check include: command, failure summary, and artifact/log path.
- Do not mark integration runs as pass without evidence artifacts.
- If a test is flaky, quarantine it and add/update the backlog item in `docs/BACKLOG.md`.
- Keep docs evergreen: do not write status/progress snapshots into runbooks.
- For new/changed behavior, include tests as part of DoD.

## Reference
- Test philosophy: `test/README.md`
- Test and release runbook: `docs/DEVOPS.md`
- Existing mocks: `test/mocks/`
- Integration journeys: `integration_test/journeys/`
- Backlog: `docs/BACKLOG.md`
