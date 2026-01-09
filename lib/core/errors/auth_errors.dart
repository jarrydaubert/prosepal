import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/log_service.dart';

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

    // Google Sign In Errors
    if (error is GoogleSignInException) {
      return _handleGoogleError(error);
    }

    // Timeout errors
    if (error is TimeoutException) {
      return const AuthErrorResult(
        message: 'Request timed out. Please try again.',
      );
    }

    // Network errors - check common patterns
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket')) {
      return const AuthErrorResult(
        message: 'Please check your internet connection and try again.',
      );
    }

    // Log unknown errors for monitoring
    Log.warning('Unhandled auth error', {'error': '$error'});

    return const AuthErrorResult(
      message: 'Something went wrong. Please try again.',
    );
  }

  /// Convert any auth exception to a user-friendly message (convenience method)
  static String getMessage(Object error) => getResult(error).message;

  static AuthErrorResult _handleAuthException(AuthException error) {
    // Normalize message for resilient matching (Supabase may change casing/spacing)
    final message = error.message.toLowerCase().trim();
    final statusCode = error.statusCode;

    // ============================================================
    // Priority 1: Check statusCode first (more reliable than message)
    // ============================================================

    // Rate limiting (429)
    if (statusCode == '429') {
      return const AuthErrorResult(
        message: 'Too many attempts. Please wait a moment and try again.',
        shouldRetry: false,
      );
    }

    // Bad request (400) - typically invalid credentials or validation
    if (statusCode == '400') {
      // Check specific message patterns within 400
      if (message.contains('invalid login credentials') ||
          message.contains('invalid email or password')) {
        return const AuthErrorResult(
          message: 'Invalid email or password. Please try again.',
        );
      }
      if (message.contains('invalid email')) {
        return const AuthErrorResult(
          message: 'Please enter a valid email address.',
        );
      }
    }

    // Unauthorized (401) - session/token issues
    if (statusCode == '401') {
      return const AuthErrorResult(
        message: 'Your session has expired. Please sign in again.',
      );
    }

    // Conflict (409) - user already exists
    if (statusCode == '409' || statusCode == '422') {
      if (message.contains('already')) {
        return const AuthErrorResult(
          message:
              'An account with this email already exists. Try signing in instead.',
          shouldRetry: false,
        );
      }
    }

    // ============================================================
    // Priority 2: Fall back to message matching for edge cases
    // ============================================================

    // Invalid credentials (fallback if statusCode not set)
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return const AuthErrorResult(
        message: 'Invalid email or password. Please try again.',
      );
    }

    // Invalid email format
    if (message.contains('invalid email')) {
      return const AuthErrorResult(
        message: 'Please enter a valid email address.',
      );
    }

    // Rate limiting (message fallback)
    if (message.contains('rate limit') ||
        message.contains('too many') ||
        message.contains('for security purposes')) {
      return const AuthErrorResult(
        message: 'Too many attempts. Please wait a moment and try again.',
        shouldRetry: false,
      );
    }

    // Email not confirmed
    // Supabase returns: "Email not confirmed"
    if (message.contains('email not confirmed')) {
      return const AuthErrorResult(
        message: 'Please check your email and confirm your account.',
        shouldRetry: false,
      );
    }

    // User already exists
    // Supabase returns: "User already registered" or "already exists"
    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return const AuthErrorResult(
        message:
            'An account with this email already exists. Try signing in instead.',
        shouldRetry: false,
      );
    }

    // Weak password
    // Supabase returns: "Password is too weak" or similar
    if (message.contains('password') && message.contains('weak')) {
      return const AuthErrorResult(
        message: 'Password is too weak. Use at least 6 characters.',
      );
    }

    // Session expired
    // Supabase returns: "Session expired", "Token expired", etc.
    if (message.contains('expired')) {
      return const AuthErrorResult(
        message: 'Your session has expired. Please sign in again.',
      );
    }

    // User cancellation (OAuth, social sign-in, etc.)
    // Various patterns: "cancelled", "canceled", "User cancelled the operation"
    if (message.contains('cancel')) {
      return const AuthErrorResult(
        message: 'Sign in was cancelled.',
        isCancellation: true,
        shouldRetry: false,
      );
    }

    // CAPTCHA required
    // Supabase returns: "captcha verification required" or similar
    if (message.contains('captcha')) {
      return const AuthErrorResult(
        message: 'Verification required. Please try again.',
        shouldRetry: false,
      );
    }

    // OAuth/provider errors
    // Supabase returns: "OAuth provider error", "Provider error", etc.
    if (message.contains('oauth') || message.contains('provider')) {
      return const AuthErrorResult(
        message: 'Sign in failed. Please try again.',
      );
    }

    // Invalid refresh token / session revoked
    if (message.contains('refresh token') ||
        message.contains('invalid token') ||
        message.contains('revoked')) {
      return const AuthErrorResult(
        message: 'Your session is no longer valid. Please sign in again.',
        shouldRetry: false,
      );
    }

    // Log unknown Supabase errors for monitoring
    Log.warning('Unhandled Supabase auth error', {
      'message': error.message,
      'statusCode': statusCode ?? 'null',
    });

    return const AuthErrorResult(
      message: 'Authentication failed. Please try again.',
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
      );
    }

    // All other cases (failed, invalidResponse, unknown, credentialExport, credentialImport, etc.)
    return const AuthErrorResult(
      message: 'Apple Sign In failed. Please try again.',
    );
  }

  static AuthErrorResult _handleGoogleError(GoogleSignInException error) {
    // Log in debug mode for monitoring
    if (kDebugMode) {
      debugPrint('Google Sign In error: ${error.code} - ${error.description}');
    }

    // User cancelled
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return const AuthErrorResult(
        message: 'Sign in was cancelled.',
        isCancellation: true,
        shouldRetry: false,
      );
    }

    // User interrupted (but not intentional cancel)
    if (error.code == GoogleSignInExceptionCode.interrupted) {
      return const AuthErrorResult(
        message: 'Sign in was interrupted. Please try again.',
      );
    }

    // Client configuration error (e.g., missing client ID)
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return const AuthErrorResult(
        message: 'Google Sign In is not available. Please try another method.',
        shouldRetry: false,
      );
    }

    // Provider configuration error (underlying SDK issue)
    if (error.code == GoogleSignInExceptionCode.providerConfigurationError) {
      return const AuthErrorResult(
        message: 'Google Sign In is not available. Please try another method.',
        shouldRetry: false,
      );
    }

    // UI unavailable (no Activity on Android, etc.)
    if (error.code == GoogleSignInExceptionCode.uiUnavailable) {
      return const AuthErrorResult(
        message: 'Unable to show sign in. Please try again.',
      );
    }

    // Unknown error - check description for network hints
    if (error.code == GoogleSignInExceptionCode.unknownError) {
      final desc = error.description?.toLowerCase() ?? '';
      if (desc.contains('network') || desc.contains('connection')) {
        return const AuthErrorResult(
          message: 'Please check your internet connection and try again.',
        );
      }
    }

    // All other cases
    return const AuthErrorResult(
      message: 'Google Sign In failed. Please try again.',
    );
  }

  /// Check if the error is a cancellation (user dismissed)
  static bool isCancellation(Object error) => getResult(error).isCancellation;

  /// Check if the error should allow retry
  static bool shouldRetry(Object error) => getResult(error).shouldRetry;
}
