import 'dart:async';

/// Result for a bounded startup phase that must never hang indefinitely.
class StartupBootstrapPhaseResult<T> {
  const StartupBootstrapPhaseResult.success({
    required this.durationMs,
    this.value,
  }) : outcome = 'ready',
       error = null,
       stackTrace = null;

  const StartupBootstrapPhaseResult.timeout({
    required this.durationMs,
    required this.error,
    required this.stackTrace,
  }) : outcome = 'timeout',
       value = null;

  const StartupBootstrapPhaseResult.failure({
    required this.durationMs,
    required this.error,
    required this.stackTrace,
  }) : outcome = 'error',
       value = null;

  final String outcome;
  final int durationMs;
  final T? value;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isSuccess => outcome == 'ready';
  bool get timedOut => outcome == 'timeout';
}

Future<StartupBootstrapPhaseResult<T>> runBoundedStartupPhase<T>({
  required Future<T> Function() operation,
  required Duration timeout,
}) async {
  final stopwatch = Stopwatch()..start();

  try {
    final value = await operation().timeout(timeout);
    return StartupBootstrapPhaseResult.success(
      durationMs: stopwatch.elapsedMilliseconds,
      value: value,
    );
  } on TimeoutException catch (error, stackTrace) {
    return StartupBootstrapPhaseResult.timeout(
      durationMs: stopwatch.elapsedMilliseconds,
      error: error,
      stackTrace: stackTrace,
    );
  } on Object catch (error, stackTrace) {
    return StartupBootstrapPhaseResult.failure(
      durationMs: stopwatch.elapsedMilliseconds,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
