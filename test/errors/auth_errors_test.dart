import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prosepal/core/errors/auth_errors.dart';

void main() {
  group('AuthErrorHandler', () {
    group('getMessage', () {
      test('should return friendly message for invalid credentials', () {
        final error = AuthException('Invalid login credentials');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Invalid email or password. Please try again.'));
      });

      test('should return friendly message for email not confirmed', () {
        final error = AuthException('Email not confirmed');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Please check your email and confirm your account.'));
      });

      test('should return friendly message for user already exists', () {
        final error = AuthException('User already registered');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('An account with this email already exists. Try signing in instead.'));
      });

      test('should return friendly message for rate limit', () {
        final error = AuthException('Rate limit exceeded');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Too many attempts. Please wait a moment and try again.'));
      });

      test('should return generic message for unknown error', () {
        final error = Exception('Unknown error');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Something went wrong. Please try again.'));
      });

      test('should return network message for network errors', () {
        final error = Exception('network error');
        final message = AuthErrorHandler.getMessage(error);
        expect(message, equals('Please check your internet connection and try again.'));
      });
    });

    group('isCancellation', () {
      test('should return false for non-cancellation errors', () {
        final error = AuthException('Invalid login credentials');
        expect(AuthErrorHandler.isCancellation(error), isFalse);
      });

      test('should return true for cancel in message', () {
        final error = AuthException('User cancelled the operation');
        expect(AuthErrorHandler.isCancellation(error), isTrue);
      });
    });
  });
}
