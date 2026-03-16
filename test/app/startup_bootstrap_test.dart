library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/app/startup_bootstrap.dart';

void main() {
  group('runBoundedStartupPhase', () {
    test('returns ready when operation completes within timeout', () async {
      final result = await runBoundedStartupPhase(
        operation: () async => 'ok',
        timeout: const Duration(milliseconds: 50),
      );

      expect(result.isSuccess, isTrue);
      expect(result.timedOut, isFalse);
      expect(result.outcome, 'ready');
      expect(result.value, 'ok');
      expect(result.error, isNull);
    });

    test('returns timeout when operation exceeds timeout budget', () async {
      final result = await runBoundedStartupPhase<void>(
        operation: () async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        },
        timeout: const Duration(milliseconds: 5),
      );

      expect(result.isSuccess, isFalse);
      expect(result.timedOut, isTrue);
      expect(result.outcome, 'timeout');
      expect(result.error, isA<TimeoutException>());
    });

    test('returns error when operation throws before timeout', () async {
      final result = await runBoundedStartupPhase<void>(
        operation: () async => throw StateError('boom'),
        timeout: const Duration(milliseconds: 50),
      );

      expect(result.isSuccess, isFalse);
      expect(result.timedOut, isFalse);
      expect(result.outcome, 'error');
      expect(result.error, isA<StateError>());
    });
  });
}
