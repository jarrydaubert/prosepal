import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for Supabase Auth operations (supabase_flutter 2.x).
///
/// Abstracts GoTrueClient for testability. All methods may throw
/// [AuthException] on failure (network, invalid credentials, etc).
///
/// ## Authentication Methods
/// - Native OAuth (Apple/Google): [signInWithIdToken]
/// - Browser OAuth (GitHub, etc): [signInWithOAuth]
/// - Email/Password: [signInWithPassword], [signUp]
/// - Magic Link: [signInWithOtp]
///
/// ## Multi-Factor Authentication (MFA)
/// Supabase supports TOTP-based MFA. Flow:
/// 1. User enrolls: [mfaEnroll] returns QR code URI
/// 2. User verifies first code: [mfaVerify] activates the factor
/// 3. On future logins: [mfaChallenge] + [mfaVerify] for aal2
/// 4. To remove: [mfaUnenroll]
///
/// Check [currentSession?.aal] for assurance level:
/// - `aal1`: Standard authentication
/// - `aal2`: MFA verified (TOTP code validated this session)
///
/// ## Captcha Integration
/// Methods accepting [captchaToken] integrate with Supabase's anti-abuse:
/// - **Required for public apps**: Sign up, password reset, OTP
/// - **Recommended for all**: Sign in (prevents credential stuffing)
/// - Get token from hCaptcha/Turnstile widget before calling
/// - If captcha is enabled in Supabase dashboard but token is null,
///   the request will fail with [AuthException]
///
/// ## Token Refresh
/// The Supabase SDK auto-refreshes tokens ~60 seconds before expiry.
/// [refreshSession] is for manual refresh (e.g., after app resume).
/// Listen to [onAuthStateChange] for [AuthChangeEvent.tokenRefreshed].
///
/// ## Deep Link Handling
/// OAuth and magic link flows redirect to your app via deep links.
/// Configure in:
/// - iOS: Info.plist URL schemes + Associated Domains
/// - Android: AndroidManifest.xml intent filters
/// - Supabase Dashboard: Authentication > URL Configuration
/// See: https://supabase.com/docs/guides/auth/native-mobile-deep-linking
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
  ///
  /// [accessToken] - Optional access token to use for authentication.
  /// If provided, bypasses session lookup which fixes timing issues when
  /// called immediately after sign-in (before session is persisted).
  Future<void> exchangeAppleToken(
    String authorizationCode, {
    String? accessToken,
  });

  /// Verify edge functions are deployed and responding
  ///
  /// Checks that required edge functions (delete-user, exchange-apple-token)
  /// are reachable. Returns a map of function names to their status.
  ///
  /// Call during app initialization to detect deployment issues early.
  /// Logs warnings for any unavailable functions but doesn't throw.
  Future<Map<String, bool>> verifyEdgeFunctions();

  // ===========================================================================
  // Multi-Factor Authentication (MFA)
  // ===========================================================================

  /// Enroll a new TOTP factor for MFA.
  ///
  /// Returns [AuthMFAEnrollResponse] containing:
  /// - `id`: Factor ID (save this for verification)
  /// - `totp.qr_code`: Data URI for QR code image
  /// - `totp.secret`: Manual entry secret for authenticator apps
  /// - `totp.uri`: otpauth:// URI for programmatic use
  ///
  /// After enrollment, user must verify with [mfaVerify] to activate.
  /// The factor is not active until first successful verification.
  ///
  /// [friendlyName] - Optional display name for the factor (e.g., "Work Phone")
  ///
  /// Throws [AuthException] if user is not authenticated.
  Future<AuthMFAEnrollResponse> mfaEnroll({String? friendlyName});

  /// Create an MFA challenge for verification.
  ///
  /// [factorId] - The factor ID from [mfaEnroll] or [mfaListFactors]
  ///
  /// Returns [AuthMFAChallengeResponse] with challenge ID needed for [mfaVerify].
  /// Challenge expires after a short time (typically 5 minutes).
  ///
  /// Call this before [mfaVerify] during login flow or when
  /// upgrading session from aal1 to aal2.
  Future<AuthMFAChallengeResponse> mfaChallenge(String factorId);

  /// Verify TOTP code to complete MFA.
  ///
  /// [factorId] - The factor ID being verified
  /// [challengeId] - Challenge ID from [mfaChallenge]
  /// [code] - 6-digit TOTP code from authenticator app
  ///
  /// On success:
  /// - For first verification: Factor becomes active
  /// - For login: Session upgraded to aal2
  ///
  /// Returns [AuthMFAVerifyResponse] with new session tokens.
  ///
  /// Throws [AuthException] if code is invalid or expired.
  Future<AuthMFAVerifyResponse> mfaVerify({
    required String factorId,
    required String challengeId,
    required String code,
  });

  /// Remove an MFA factor.
  ///
  /// [factorId] - The factor ID to remove
  ///
  /// User must have aal2 session to unenroll factors.
  /// If this is the last factor, user returns to aal1-only auth.
  ///
  /// Throws [AuthException] if factor not found or insufficient privileges.
  Future<AuthMFAUnenrollResponse> mfaUnenroll(String factorId);

  /// List all MFA factors for current user.
  ///
  /// Returns [AuthMFAListFactorsResponse] containing:
  /// - `all`: All enrolled factors
  /// - `totp`: TOTP factors only
  ///
  /// Each factor includes:
  /// - `id`: Factor ID for challenge/verify/unenroll
  /// - `friendlyName`: Display name if provided

  /// - `status`: 'verified' or 'unverified'
  /// - `createdAt`: Enrollment timestamp
  ///
  /// Use to check if user has MFA enabled and show management UI.
  Future<AuthMFAListFactorsResponse> mfaListFactors();

  /// Get current MFA/AAL status.
  ///
  /// Returns [AuthMFAGetAuthenticatorAssuranceLevelResponse]:
  /// - `currentLevel`: Current AAL ('aal1' or 'aal2')
  /// - `nextLevel`: Required AAL based on enrolled factors
  /// - `currentAuthenticationMethods`: Methods used this session
  ///
  /// Use to determine if user needs to complete MFA challenge:
  /// ```dart
  /// final status = await mfaGetAuthenticatorAssuranceLevel();
  /// if (status.nextLevel == 'aal2' && status.currentLevel == 'aal1') {
  ///   // User has MFA enabled but hasn't verified this session
  ///   // Show MFA challenge screen
  /// }
  /// ```
  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse>
      mfaGetAuthenticatorAssuranceLevel();
}
