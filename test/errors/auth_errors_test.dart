import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prosepal/core/errors/auth_errors.dart';

void main() {
  group('AuthErrorResult', () {
    test('should create with required message', () {
      const result = AuthErrorResult(message: 'Test error');
      expect(result.message, equals('Test error'));
      expect(result.isCancellation, isFalse);
      expect(result.shouldRetry, isTrue);
    });

    test('should allow custom isCancellation', () {
      const result = AuthErrorResult(
        message: 'Cancelled',
        isCancellation: true,
      );
      expect(result.isCancellation, isTrue);
    });

    test('should allow custom shouldRetry', () {
      const result = AuthErrorResult(
        message: 'Rate limited',
        shouldRetry: false,
      );
      expect(result.shouldRetry, isFalse);
    });
  });

  group('AuthErrorHandler', () {
    group('getMessage', () {
      test('should return friendly message for invalid credentials', () {
        const error = AuthException('Invalid login credentials');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Invalid email or password. Please try again.'));
      });

      test('should return friendly message for email not confirmed', () {
        const error = AuthException('Email not confirmed');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Please check your email and confirm your account.'),
        );
      });

      test('should return friendly message for user already exists', () {
        const error = AuthException('User already registered');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals(
            'An account with this email already exists. Try signing in instead.',
          ),
        );
      });

      test('should return friendly message for rate limit', () {
        const error = AuthException('Rate limit exceeded');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Too many attempts. Please wait a moment and try again.'),
        );
      });

      test('should return friendly message for too many requests', () {
        const error = AuthException('Too many requests');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Too many attempts. Please wait a moment and try again.'),
        );
      });

      test('should return friendly message for email rate limit', () {
        const error = AuthException('Email rate limit exceeded');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Too many attempts. Please wait a moment and try again.'),
        );
      });

      test('should return friendly message for security rate limit', () {
        const error = AuthException(
          'For security purposes, you can only request this once every 60 seconds',
        );
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Too many attempts. Please wait a moment and try again.'),
        );
      });

      test('should return generic message for unknown error', () {
        final error = Exception('Unknown error');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Something went wrong. Please try again.'));
      });

      test('should return network message for network errors', () {
        final error = Exception('network error');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Please check your internet connection and try again.'),
        );
      });

      test('should return network message for connection errors', () {
        final error = Exception('connection failed');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Please check your internet connection and try again.'),
        );
      });

      test('should return network message for socket errors', () {
        final error = Exception('socket exception');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Please check your internet connection and try again.'),
        );
      });

      test('should return timeout message for TimeoutException', () {
        final error = TimeoutException('Request timed out');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Request timed out. Please try again.'));
      });

      test('should return friendly message for weak password', () {
        const error = AuthException('Password is too weak');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Password is too weak. Use at least 6 characters.'),
        );
      });

      test('should return friendly message for invalid email', () {
        const error = AuthException('Invalid email format');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Please enter a valid email address.'));
      });

      test('should return friendly message for expired session', () {
        const error = AuthException('Session expired');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Your session has expired. Please sign in again.'),
        );
      });

      test('should return friendly message for oauth errors', () {
        const error = AuthException('OAuth provider error');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Sign in failed. Please try again.'));
      });

      test('should return cancellation message for cancelled auth', () {
        const error = AuthException('User cancelled the operation');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Sign in was cancelled.'));
      });

      test('should return expired message for expired magic link', () {
        const error = AuthException('Email link is invalid or has expired');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Your session has expired. Please sign in again.'),
        );
      });

      test('should return expired message for token expired', () {
        const error = AuthException('Token has expired');
        final message = AuthErrorHandler.getMessage(error);
        expect(
          message,
          equals('Your session has expired. Please sign in again.'),
        );
      });
    });

    group('getResult', () {
      test('should return structured result for invalid credentials', () {
        const error = AuthException('Invalid login credentials');
        final result = AuthErrorHandler.getResult(error);
        expect(
          result.message,
          equals('Invalid email or password. Please try again.'),
        );
        expect(result.isCancellation, isFalse);
        expect(result.shouldRetry, isTrue);
      });

      test('should mark rate limit as not retryable', () {
        const error = AuthException('Rate limit exceeded');
        final result = AuthErrorHandler.getResult(error);
        expect(result.shouldRetry, isFalse);
      });

      test('should mark email not confirmed as not retryable', () {
        const error = AuthException('Email not confirmed');
        final result = AuthErrorHandler.getResult(error);
        expect(result.shouldRetry, isFalse);
      });

      test('should mark user exists as not retryable', () {
        const error = AuthException('User already registered');
        final result = AuthErrorHandler.getResult(error);
        expect(result.shouldRetry, isFalse);
      });

      test('should mark cancellation correctly', () {
        const error = AuthException('User cancelled');
        final result = AuthErrorHandler.getResult(error);
        expect(result.isCancellation, isTrue);
        expect(result.shouldRetry, isFalse);
      });

      test('should mark timeout as retryable', () {
        final error = TimeoutException('Timed out');
        final result = AuthErrorHandler.getResult(error);
        expect(result.shouldRetry, isTrue);
      });
    });

    group('isCancellation', () {
      test('should return false for non-cancellation errors', () {
        const error = AuthException('Invalid login credentials');
        expect(AuthErrorHandler.isCancellation(error), isFalse);
      });

      test('should return true for cancel in message', () {
        const error = AuthException('User cancelled the operation');
        expect(AuthErrorHandler.isCancellation(error), isTrue);
      });

      test('should return false for generic exception', () {
        final error = Exception('Something failed');
        expect(AuthErrorHandler.isCancellation(error), isFalse);
      });
    });

    group('shouldRetry', () {
      test('should return true for retryable errors', () {
        const error = AuthException('Invalid login credentials');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });

      test('should return false for rate limit', () {
        const error = AuthException('Rate limit exceeded');
        expect(AuthErrorHandler.shouldRetry(error), isFalse);
      });

      test('should return false for cancellation', () {
        const error = AuthException('User cancelled');
        expect(AuthErrorHandler.shouldRetry(error), isFalse);
      });

      test('should return true for timeout', () {
        final error = TimeoutException('Timed out');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });

      test('should return true for network errors', () {
        final error = Exception('network error');
        expect(AuthErrorHandler.shouldRetry(error), isTrue);
      });
    });
  });
}
