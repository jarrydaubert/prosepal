import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Structured result for richer UI handling
class AuthErrorResult {
  const AuthErrorResult({
    required this.message,
    this.isCancellation = false,
    this.shouldRetry = true,
  });

  final String message;
  final bool isCancellation;
  final bool shouldRetry;
}

/// User-friendly error messages for authentication
class AuthErrorHandler {
  AuthErrorHandler._();

  /// Convert any auth exception to a structured result
  static AuthErrorResult getResult(Object error) {
    // Supabase Auth Errors
    if (error is AuthException) {
      return _handleAuthException(error);
    }

    // Apple Sign In Errors
    if (error is SignInWithAppleAuthorizationException) {
      return _handleAppleError(error);
    }

    // Timeout errors
    if (error is TimeoutException) {
      return const AuthErrorResult(
        message: 'Request timed out. Please try again.',
        shouldRetry: true,
      );
    }

    // Network errors - check common patterns
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket')) {
      return const AuthErrorResult(
        message: 'Please check your internet connection and try again.',
        shouldRetry: true,
      );
    }

    // Log unknown errors in debug mode
    if (kDebugMode) {
      debugPrint('Unhandled auth error: $error');
    }

    return const AuthErrorResult(
      message: 'Something went wrong. Please try again.',
      shouldRetry: true,
    );
  }

  /// Convert any auth exception to a user-friendly message (convenience method)
  static String getMessage(Object error) => getResult(error).message;

  static AuthErrorResult _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;

    // Invalid credentials - check message first (statusCode may be null in tests)
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return const AuthErrorResult(
        message: 'Invalid email or password. Please try again.',
        shouldRetry: true,
      );
    }

    // Invalid email format
    if (message.contains('invalid email')) {
      return const AuthErrorResult(
        message: 'Please enter a valid email address.',
        shouldRetry: true,
      );
    }

    // Rate limiting (429 or message-based)
    if (statusCode == '429' ||
        message.contains('rate limit') ||
        message.contains('too many')) {
      return const AuthErrorResult(
        message: 'Too many attempts. Please wait a moment and try again.',
        shouldRetry: false, // Don't immediately retry rate limits
      );
    }

    // Email not confirmed
    if (message.contains('email not confirmed')) {
      return const AuthErrorResult(
        message: 'Please check your email and confirm your account.',
        shouldRetry: false,
      );
    }

    // User already exists
    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return const AuthErrorResult(
        message:
            'An account with this email already exists. Try signing in instead.',
        shouldRetry: false,
      );
    }

    // Weak password
    if (message.contains('password') && message.contains('weak')) {
      return const AuthErrorResult(
        message: 'Password is too weak. Use at least 6 characters.',
        shouldRetry: true,
      );
    }

    // Invalid email format
    if (message.contains('invalid email')) {
      return const AuthErrorResult(
        message: 'Please enter a valid email address.',
        shouldRetry: true,
      );
    }

    // Session expired
    if (message.contains('expired')) {
      return const AuthErrorResult(
        message: 'Your session has expired. Please sign in again.',
        shouldRetry: true,
      );
    }

    // OAuth errors (includes cancellation)
    if (message.contains('cancel')) {
      return const AuthErrorResult(
        message: 'Sign in was cancelled.',
        isCancellation: true,
        shouldRetry: false,
      );
    }

    if (message.contains('oauth') || message.contains('provider')) {
      return const AuthErrorResult(
        message: 'Sign in failed. Please try again.',
        shouldRetry: true,
      );
    }

    // Log unknown Supabase errors in debug mode
    if (kDebugMode) {
      debugPrint(
        'Unhandled Supabase auth error: ${error.message} (status: $statusCode)',
      );
    }

    return const AuthErrorResult(
      message: 'Authentication failed. Please try again.',
      shouldRetry: true,
    );
  }

  static AuthErrorResult _handleAppleError(
    SignInWithAppleAuthorizationException error,
  ) {
    // Log unknown codes in debug mode for monitoring
    if (kDebugMode) {
      debugPrint('Apple Sign In error: ${error.code} - ${error.message}');
    }

    // Handle known cases explicitly, with default for future codes
    if (error.code == AuthorizationErrorCode.canceled) {
      return const AuthErrorResult(
        message: 'Sign in was cancelled.',
        isCancellation: true,
        shouldRetry: false,
      );
    }

    if (error.code == AuthorizationErrorCode.notHandled) {
      return const AuthErrorResult(
        message: 'Apple Sign In is not available on this device.',
        shouldRetry: false,
      );
    }

    if (error.code == AuthorizationErrorCode.notInteractive) {
      return const AuthErrorResult(
        message: 'Apple Sign In requires interaction. Please try again.',
        shouldRetry: true,
      );
    }

    // All other cases (failed, invalidResponse, unknown, credentialExport, credentialImport, etc.)
    return const AuthErrorResult(
      message: 'Apple Sign In failed. Please try again.',
      shouldRetry: true,
    );
  }

  /// Check if the error is a cancellation (user dismissed)
  static bool isCancellation(Object error) => getResult(error).isCancellation;

  /// Check if the error should allow retry
  static bool shouldRetry(Object error) => getResult(error).shouldRetry;
}
