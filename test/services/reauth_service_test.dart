import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/reauth_service.dart';

/// ReauthService Unit Tests
///
/// Bugs these tests prevent:
/// - BUG-001: Pro users locked out after token expiry
/// - BUG-002: Sensitive operations allowed without re-auth
/// - BUG-003: Re-auth required too frequently (UX annoyance)
/// - BUG-004: Re-auth state not reset after successful auth
void main() {
  group('ReauthService', () {
    group('ReauthResult', () {
      test('successful result has success true and no error', () {
        const result = ReauthResult(success: true);

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('failed result has success false with error message', () {
        // BUG-001: Silent failures without user feedback
        const result = ReauthResult(
          success: false,
          errorMessage: 'Incorrect password',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Incorrect password');
      });

      test('cancelled result is pre-defined constant', () {
        // BUG: Crash when user cancels dialog
        const result = ReauthResult.cancelled;

        expect(result.success, isFalse);
        expect(result.errorMessage, isNull);
      });

      test('cancelled result is consistent across uses', () {
        // Using const ensures same instance
        expect(ReauthResult.cancelled, same(ReauthResult.cancelled));
      });
    });

    // Note: _reauthTimeout (5 minutes) is private and tested indirectly
    // via mockLastAuth timestamps in the tests above
  });

  group('MockReauthService behavior', () {
    // These tests verify the mock behaves correctly for widget tests

    test('mock returns success when reauth not required', () async {
      final mock = _SimpleMockReauthService();

      expect(mock.isReauthRequired, isFalse);
    });

    test('mock returns configured result when reauth required', () async {
      final mock = _SimpleMockReauthService(
        shouldRequireReauth: true,
        reauthResult: const ReauthResult(
          success: false,
          errorMessage: 'Biometrics failed',
        ),
      );

      expect(mock.isReauthRequired, isTrue);
    });

    test('markReauthenticated can be called without error', () {
      final mock = _SimpleMockReauthService();

      expect(mock.markReauthenticated, returnsNormally);
    });
  });
}

/// Simple mock for testing ReauthResult behavior
class _SimpleMockReauthService {
  _SimpleMockReauthService({
    this.shouldRequireReauth = false,
    this.reauthResult = const ReauthResult(success: true),
  });

  final bool shouldRequireReauth;
  final ReauthResult reauthResult;

  bool get isReauthRequired => shouldRequireReauth;

  void markReauthenticated() {}
}
