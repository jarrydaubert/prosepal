/// Tests for AuthErrorHandler and AuthErrorResult.
///
/// Validates user-friendly error message mapping for:
/// - Supabase AuthException (message and statusCode based)
/// - Apple Sign In exceptions (SignInWithAppleAuthorizationException)
/// - Google Sign In exceptions (GoogleSignInException)
/// - Network errors and timeouts
///
/// Tests verify message content, cancellation detection, and retry logic.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prosepal/core/errors/auth_errors.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// Test Data - Supabase AuthException cases
// =============================================================================

/// Supabase errors: (message, expectedFriendlyMessage, shouldRetry, isCancellation)
const _supabaseErrorCases = <(String, String, bool, bool)>[
  // Invalid credentials
  (
    'Invalid login credentials',
    'Invalid email or password. Please try again.',
    true,
    false,
  ),
  (
    'invalid email or password',
    'Invalid email or password. Please try again.',
    true,
    false,
  ),
  // Email not confirmed
  (
    'Email not confirmed',
    'Please check your email and confirm your account.',
    false,
    false,
  ),
  // User already exists
  (
    'User already registered',
    'An account with this email already exists. Try signing in instead.',
    false,
    false,
  ),
  (
    'User already exists',
    'An account with this email already exists. Try signing in instead.',
    false,
    false,
  ),
  // Rate limiting (multiple patterns)
  (
    'Rate limit exceeded',
    'Too many attempts. Please wait a moment and try again.',
    false,
    false,
  ),
  (
    'Too many requests',
    'Too many attempts. Please wait a moment and try again.',
    false,
    false,
  ),
  (
    'Email rate limit exceeded',
    'Too many attempts. Please wait a moment and try again.',
    false,
    false,
  ),
  (
    'For security purposes, you can only request this once every 60 seconds',
    'Too many attempts. Please wait a moment and try again.',
    false,
    false,
  ),
  // Weak password
  (
    'Password is too weak',
    'Password is too weak. Use at least 6 characters.',
    true,
    false,
  ),
  // Invalid email
  (
    'Invalid email format',
    'Please enter a valid email address.',
    true,
    false,
  ),
  (
    'Invalid email',
    'Please enter a valid email address.',
    true,
    false,
  ),
  // Session/token expired
  (
    'Session expired',
    'Your session has expired. Please sign in again.',
    true,
    false,
  ),
  (
    'Token has expired',
    'Your session has expired. Please sign in again.',
    true,
    false,
  ),
  (
    'Email link is invalid or has expired',
    'Your session has expired. Please sign in again.',
    true,
    false,
  ),
  // OAuth/provider errors
  (
    'OAuth provider error',
    'Sign in failed. Please try again.',
    true,
    false,
  ),
  (
    'Provider error occurred',
    'Sign in failed. Please try again.',
    true,
    false,
  ),
  // Cancellation
  (
    'User cancelled the operation',
    'Sign in was cancelled.',
    false,
    true,
  ),
  (
    'User canceled',
    'Sign in was cancelled.',
    false,
    true,
  ),
  // CAPTCHA
  (
    'captcha verification required',
    'Verification required. Please try again.',
    false,
    false,
  ),
  // Refresh token / revoked
  (
    'Refresh token not found',
    'Your session is no longer valid. Please sign in again.',
    false,
    false,
  ),
  (
    'Session has been revoked',
    'Your session is no longer valid. Please sign in again.',
    false,
    false,
  ),
];

/// Supabase status code cases: (statusCode, message, expectedFriendlyMessage)
const _supabaseStatusCodeCases = <(String, String, String)>[
  ('429', 'any message', 'Too many attempts. Please wait a moment and try again.'),
  ('401', 'any message', 'Your session has expired. Please sign in again.'),
  ('400', 'Invalid login credentials', 'Invalid email or password. Please try again.'),
  ('400', 'Invalid email', 'Please enter a valid email address.'),
  ('409', 'User already exists', 'An account with this email already exists. Try signing in instead.'),
  ('422', 'User already registered', 'An account with this email already exists. Try signing in instead.'),
];

/// Network error patterns
const _networkErrorPatterns = <String>[
  'network error',
  'Network request failed',
  'connection failed',
  'Connection timed out',
  'socket exception',
  'SocketException',
];

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AuthErrorResult', () {
    test('should create with required message and default flags', () {
      const result = AuthErrorResult(message: 'Test error');
      expect(result.message, 'Test error');
      expect(result.isCancellation, isFalse);
      expect(result.shouldRetry, isTrue);
    });

    test('should allow custom isCancellation flag', () {
      const result = AuthErrorResult(message: 'Cancelled', isCancellation: true);
      expect(result.isCancellation, isTrue);
    });

    test('should allow custom shouldRetry flag', () {
      const result = AuthErrorResult(message: 'Rate limited', shouldRetry: false);
      expect(result.shouldRetry, isFalse);
    });
  });

  group('AuthErrorHandler', () {
    group('Supabase AuthException (message-based)', () {
      for (final (message, expected, retry, cancel) in _supabaseErrorCases) {
        test('$message -> "$expected"', () {
          final error = AuthException(message);
          final result = AuthErrorHandler.getResult(error);

          expect(result.message, expected);
          expect(result.shouldRetry, retry, reason: 'shouldRetry');
          expect(result.isCancellation, cancel, reason: 'isCancellation');
        });
      }
    });

    group('Supabase AuthException (statusCode-based)', () {
      for (final (code, message, expected) in _supabaseStatusCodeCases) {
        test('statusCode $code with "$message" -> "$expected"', () {
          final error = AuthException(message, statusCode: code);
          final result = AuthErrorHandler.getResult(error);
          expect(result.message, expected);
        });
      }

      test('statusCode 429 takes priority over message', () {
        // Even if message doesn't mention rate limit, 429 = rate limit
        final error = AuthException('Some random message', statusCode: '429');
        expect(
          AuthErrorHandler.getMessage(error),
          'Too many attempts. Please wait a moment and try again.',
        );
      });
    });

    group('Apple Sign In exceptions', () {
      test('canceled -> cancellation message', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'User cancelled',
        );
        final result = AuthErrorHandler.getResult(error);

        expect(result.message, 'Sign in was cancelled.');
        expect(result.isCancellation, isTrue);
        expect(result.shouldRetry, isFalse);
      });

      test('notHandled -> not available message', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.notHandled,
          message: 'Not handled',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Apple Sign In is not available on this device.',
        );
      });

      test('notInteractive -> try again message', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.notInteractive,
          message: 'Not interactive',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Apple Sign In requires interaction. Please try again.',
        );
      });

      test('failed -> generic Apple failure', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.failed,
          message: 'Failed',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Apple Sign In failed. Please try again.',
        );
      });

      test('unknown -> generic Apple failure', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.unknown,
          message: 'Unknown error',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Apple Sign In failed. Please try again.',
        );
      });
    });

    group('Google Sign In exceptions', () {
      test('canceled -> cancellation message', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'User cancelled',
        );
        final result = AuthErrorHandler.getResult(error);

        expect(result.message, 'Sign in was cancelled.');
        expect(result.isCancellation, isTrue);
        expect(result.shouldRetry, isFalse);
      });

      test('interrupted -> interrupted message', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.interrupted,
          description: 'Interrupted',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Sign in was interrupted. Please try again.',
        );
      });

      test('clientConfigurationError -> not available', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'Missing client ID',
        );
        final result = AuthErrorHandler.getResult(error);

        expect(
          result.message,
          'Google Sign In is not available. Please try another method.',
        );
        expect(result.shouldRetry, isFalse);
      });

      test('providerConfigurationError -> not available', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: 'SDK error',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Google Sign In is not available. Please try another method.',
        );
      });

      test('uiUnavailable -> try again', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.uiUnavailable,
          description: 'No activity',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Unable to show sign in. Please try again.',
        );
      });

      test('unknownError with network hint -> network message', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Network connection failed',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Please check your internet connection and try again.',
        );
      });

      test('unknownError generic -> Google failure', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Something went wrong',
        );
        expect(
          AuthErrorHandler.getMessage(error),
          'Google Sign In failed. Please try again.',
        );
      });
    });

    group('Network errors', () {
      for (final pattern in _networkErrorPatterns) {
        test('"$pattern" -> network message', () {
          final error = Exception(pattern);
          expect(
            AuthErrorHandler.getMessage(error),
            'Please check your internet connection and try again.',
          );
          expect(AuthErrorHandler.shouldRetry(error), isTrue);
        });
      }
    });

    group('Timeout errors', () {
      test('TimeoutException -> timeout message', () {
        final error = TimeoutException('Request timed out');
        final result = AuthErrorHandler.getResult(error);

        expect(result.message, 'Request timed out. Please try again.');
        expect(result.shouldRetry, isTrue);
      });
    });

    group('Unknown errors', () {
      test('generic Exception -> fallback message', () {
        final error = Exception('Something completely unexpected');
        expect(
          AuthErrorHandler.getMessage(error),
          'Something went wrong. Please try again.',
        );
      });

      test('generic Error -> fallback message', () {
        final error = StateError('State error');
        expect(
          AuthErrorHandler.getMessage(error),
          'Something went wrong. Please try again.',
        );
      });
    });

    group('isCancellation helper', () {
      test('returns true for Supabase cancel', () {
        const error = AuthException('User cancelled');
        expect(AuthErrorHandler.isCancellation(error), isTrue);
      });

      test('returns true for Apple cancel', () {
        final error = SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'Cancelled',
        );
        expect(AuthErrorHandler.isCancellation(error), isTrue);
      });

      test('returns true for Google cancel', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
        expect(AuthErrorHandler.isCancellation(error), isTrue);
      });

      test('returns false for non-cancellation', () {
        const error = AuthException('Invalid credentials');
        expect(AuthErrorHandler.isCancellation(error), isFalse);
      });
    });

    group('shouldRetry helper', () {
      test('returns true for invalid credentials', () {
        const error = AuthException('Invalid login credentials');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });

      test('returns false for rate limit', () {
        const error = AuthException('Rate limit exceeded');
        expect(AuthErrorHandler.shouldRetry(error), isFalse);
      });

      test('returns false for cancellation', () {
        const error = AuthException('User cancelled');
        expect(AuthErrorHandler.shouldRetry(error), isFalse);
      });

      test('returns true for timeout', () {
        final error = TimeoutException('Timed out');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });

      test('returns true for network errors', () {
        final error = Exception('network error');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });

      test('returns false for config errors', () {
        const error = GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
        expect(AuthErrorHandler.shouldRetry(error), isFalse);
      });
    });
  });
}
