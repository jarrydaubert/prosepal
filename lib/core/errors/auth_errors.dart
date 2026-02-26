import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-friendly error messages for authentication
class AuthErrorHandler {
  AuthErrorHandler._();

  /// Convert any auth exception to a user-friendly message
  static String getMessage(Object error) {
    // Supabase Auth Errors
    if (error is AuthException) {
      return _handleAuthException(error);
    }

    // Apple Sign In Errors
    if (error is SignInWithAppleAuthorizationException) {
      return _handleAppleError(error);
    }

    // Generic errors
    if (error.toString().contains('network')) {
      return 'Please check your internet connection and try again.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    // Email/Password errors
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please check your email and confirm your account.';
    }

    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }

    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (message.contains('expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    // OAuth errors
    if (message.contains('oauth') || message.contains('provider')) {
      return 'Sign in was cancelled or failed. Please try again.';
    }

    return 'Authentication failed. Please try again.';
  }

  static String _handleAppleError(SignInWithAppleAuthorizationException error) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign in was cancelled.';
      case AuthorizationErrorCode.failed:
        return 'Apple Sign In failed. Please try again.';
      case AuthorizationErrorCode.invalidResponse:
        return 'Invalid response from Apple. Please try again.';
      case AuthorizationErrorCode.notHandled:
        return 'Apple Sign In is not available on this device.';
      case AuthorizationErrorCode.notInteractive:
        return 'Apple Sign In requires interaction. Please try again.';
      case AuthorizationErrorCode.unknown:
      default:
        return 'Apple Sign In failed. Please try again.';
    }
  }

  /// Check if the error is a cancellation (user dismissed)
  static bool isCancellation(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      return error.code == AuthorizationErrorCode.canceled;
    }
    if (error is AuthException) {
      return error.message.toLowerCase().contains('cancel');
    }
    return false;
  }
}
