import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for Supabase Auth operations
///
/// Abstracts GoTrueClient for testability. All methods may throw
/// [AuthException] on failure (network, invalid credentials, etc).
///
/// For native mobile OAuth (Apple/Google), use [signInWithIdToken].
/// For browser-based OAuth, use [signInWithOAuth].
abstract class ISupabaseAuthProvider {
  /// Current authenticated user (null if not logged in)
  User? get currentUser;

  /// Current session (null if not logged in)
  Session? get currentSession;

  /// Stream of auth state changes
  ///
  /// Listen to this for login/logout events, token refresh, etc.
  /// Emits immediately with current state on subscription.
  Stream<AuthState> get onAuthStateChange;

  // ===========================================================================
  // OAuth / Native Sign In
  // ===========================================================================

  /// Sign in with ID token from native OAuth provider (Apple, Google)
  ///
  /// Use for native SDK sign-in flows where you obtain tokens client-side.
  /// [provider] - OAuthProvider.apple or OAuthProvider.google
  /// [idToken] - JWT identity token from provider
  /// [nonce] - Raw nonce for Apple (hashed nonce was sent to Apple SDK)
  /// [accessToken] - Access token for Google (optional but recommended)
  ///
  /// Throws [AuthException] on invalid token or network failure.
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  });

  /// Sign in with OAuth provider via browser/webview flow
  ///
  /// Use for providers without native SDK (GitHub, Discord, etc) or web.
  /// [provider] - OAuth provider enum
  /// [redirectTo] - Deep link URL to return to app after auth
  /// [scopes] - Additional OAuth scopes to request
  /// [queryParams] - Extra query parameters for auth URL
  ///
  /// Returns true if browser was launched successfully.
  /// Auth result comes via [onAuthStateChange] after redirect.
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  });

  // ===========================================================================
  // Email / Password
  // ===========================================================================

  /// Sign in with email and password
  ///
  /// Throws [AuthException] on invalid credentials.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  });

  /// Sign up with email and password
  ///
  /// [data] - Optional user metadata (stored in user.user_metadata)
  /// [captchaToken] - Captcha verification token if enabled
  ///
  /// Note: User may need to confirm email depending on project settings.
  /// Check response.user?.confirmedAt to determine confirmation status.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? captchaToken,
  });

  /// Send password reset email
  ///
  /// [redirectTo] - Deep link URL for password reset page in app
  /// [captchaToken] - Captcha verification token if enabled
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  });

  // ===========================================================================
  // Magic Link / OTP
  // ===========================================================================

  /// Sign in with magic link (passwordless OTP)
  ///
  /// Sends email with magic link. User clicks link to authenticate.
  /// [emailRedirectTo] - Deep link URL to handle auth in app
  /// [captchaToken] - Captcha verification token if enabled
  ///
  /// Requires deep link handling in app to capture the auth callback.
  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
    String? captchaToken,
  });

  // ===========================================================================
  // Session Management
  // ===========================================================================

  /// Refresh the current session
  ///
  /// Manually refresh tokens before they expire. Useful for long-running
  /// operations or when resuming from background.
  /// Returns new session or throws if refresh token is invalid/expired.
  Future<AuthResponse> refreshSession();

  /// Set session from refresh token
  ///
  /// Recover session from stored refresh token (e.g., secure storage).
  /// Use when restoring auth state from external persistence.
  Future<AuthResponse> setSession(String refreshToken);

  // ===========================================================================
  // User Management
  // ===========================================================================

  /// Update user attributes (email, password, metadata)
  ///
  /// Use UserAttributes to specify what to update:
  /// - UserAttributes(email: 'new@email.com')
  /// - UserAttributes(password: 'newPassword')
  /// - UserAttributes(data: {'name': 'New Name'})
  ///
  /// Email changes may require confirmation depending on settings.
  Future<UserResponse> updateUser(UserAttributes attributes);

  /// Sign out current user
  ///
  /// Clears local session. Does not revoke server-side tokens.
  Future<void> signOut();

  /// Delete user account
  ///
  /// Permanently deletes the authenticated user. Requires service role
  /// or edge function with admin privileges - typically call via edge function.
  /// This method is for the RPC/function call pattern.
  Future<void> deleteUser();

  /// Exchange Apple authorization code for refresh token
  ///
  /// Call immediately after Apple Sign In to exchange the short-lived
  /// authorization code for a long-lived refresh token. The refresh token
  /// is stored server-side and used to revoke Apple tokens when the user
  /// deletes their account (Apple compliance requirement).
  ///
  /// The authorization code expires in 5 minutes, so this must be called
  /// immediately after sign-in succeeds.
  Future<void> exchangeAppleToken(String authorizationCode);
}
