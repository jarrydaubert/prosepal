import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for authentication services.
///
/// Allows mocking in tests without Supabase dependency. All methods that
/// interact with the auth backend may throw [AuthException] on failure.
///
/// ## Preconditions
/// - Supabase must be initialized before calling any method
/// - [initializeProviders] should be called at app startup for OAuth flows
///
/// ## Error Handling
/// Use [AuthErrorHandler] from `auth_errors.dart` to convert exceptions
/// to user-friendly messages. All sign-in methods may throw:
/// - [AuthException] for Supabase errors (rate limit, invalid credentials, etc.)
/// - [SignInWithAppleAuthorizationException] for Apple-specific errors
/// - [GoogleSignInException] for Google-specific errors
/// - [TimeoutException] for network timeouts
abstract class IAuthService {
  /// Initialize OAuth providers at app startup for faster sign-in.
  ///
  /// Call once during app initialization, before showing auth UI.
  /// Silently handles initialization failures (logs warning, doesn't throw).
  Future<void> initializeProviders();

  /// Current authenticated user, or null if not logged in.
  User? get currentUser;

  /// Whether a user is currently logged in.
  bool get isLoggedIn;

  /// Stream of auth state changes for reactive UI updates.
  ///
  /// Emits on sign-in, sign-out, token refresh, and session expiry.
  Stream<AuthState> get authStateChanges;

  /// User's display name from profile, or null if not set.
  String? get displayName;

  /// User's email address, or null if not available.
  String? get email;

  /// Sign in with Apple using native SDK.
  ///
  /// Throws [SignInWithAppleAuthorizationException] on Apple errors.
  /// Throws [AuthException] on Supabase token exchange errors.
  /// Returns [AuthResponse] with session on success.
  Future<AuthResponse> signInWithApple();

  /// Sign in with Google using native SDK.
  ///
  /// Throws [GoogleSignInException] on Google errors.
  /// Throws [AuthException] on Supabase token exchange errors.
  /// Returns [AuthResponse] with session on success.
  Future<AuthResponse> signInWithGoogle();

  /// Sign in with email and password.
  ///
  /// Throws [AuthException] with status 400 for invalid credentials.
  /// Throws [AuthException] with status 429 for rate limiting.
  /// Returns [AuthResponse] with session on success.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create new account with email and password.
  ///
  /// Throws [AuthException] with status 409/422 if email already exists.
  /// Throws [AuthException] if password is too weak.
  /// Returns [AuthResponse] (may require email confirmation depending on settings).
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Send password reset email.
  ///
  /// Throws [AuthException] on failure (but not if email doesn't exist,
  /// for security - prevents email enumeration).
  Future<void> resetPassword(String email);

  /// Send magic link for passwordless sign-in.
  ///
  /// Throws [AuthException] on failure (rate limit, invalid email format).
  Future<void> signInWithMagicLink(String email);

  /// Update current user's email address.
  ///
  /// Requires active session. Throws [AuthException] if not logged in.
  /// May require email confirmation depending on Supabase settings.
  Future<void> updateEmail(String newEmail);

  /// Update current user's password.
  ///
  /// Requires active session. Throws [AuthException] if not logged in
  /// or if new password is too weak.
  Future<void> updatePassword(String newPassword);

  /// Sign out current user from all sessions.
  ///
  /// Clears local session. Safe to call even if not logged in.
  Future<void> signOut();

  /// Permanently delete current user's account and all data.
  ///
  /// Requires active session. Throws [AuthException] if not logged in.
  /// Calls server-side edge function to clean up user data.
  /// This action is irreversible.
  Future<void> deleteAccount();
}
