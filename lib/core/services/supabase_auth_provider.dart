import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

import '../interfaces/supabase_auth_provider.dart';
import 'log_service.dart';

/// Real implementation using Supabase Flutter SDK (supabase_flutter 2.x)
///
/// ## Architecture
/// Uses [Supabase.instance.client] singleton for all operations. This provider
/// wraps [GoTrueClient] for auth and [FunctionsClient] for edge functions.
///
/// ## Error Handling
/// All methods may throw [AuthException] on failure. Common error codes:
/// - `invalid_credentials`: Wrong email/password
/// - `email_not_confirmed`: User hasn't verified email
/// - `user_not_found`: No user with given identifier
/// - `weak_password`: Password doesn't meet requirements
/// - `rate_limit`: Too many requests
///
/// ## Platform Notes
/// - **Deep Links**: Required for mobile OTP/OAuth/password-reset callbacks.
///   Configure in Supabase Dashboard > Authentication > URL Configuration.
/// - **Captcha**: Optional but recommended for public-facing auth endpoints.
///   Enable in Supabase Dashboard > Authentication > Captcha Protection.
///
/// ## Edge Function Requirements
/// [deleteUser] requires a deployed edge function with service-role access.
/// The function uses dual-client pattern: verify user with anon key, delete with service role.
///
/// Deploy via: `supabase functions deploy delete-user`
///
/// ```typescript
/// // supabase/functions/delete-user/index.ts
/// import { createClient } from 'npm:@supabase/supabase-js@2'
///
/// const corsHeaders = {
///   'Access-Control-Allow-Origin': '*',
///   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
///   'Access-Control-Allow-Methods': 'POST, OPTIONS',
/// }
///
/// Deno.serve(async (req) => {
///   // Handle CORS preflight
///   if (req.method === 'OPTIONS') {
///     return new Response('ok', { headers: corsHeaders })
///   }
///
///   const authHeader = req.headers.get('Authorization')
///   if (!authHeader) {
///     return new Response('Missing auth header', { status: 401, headers: corsHeaders })
///   }
///
///   // Verify user with their token (anon key)
///   const userClient = createClient(
///     Deno.env.get('SUPABASE_URL')!,
///     Deno.env.get('SUPABASE_ANON_KEY')!,
///     { global: { headers: { Authorization: authHeader } } }
///   )
///   const { data: { user }, error } = await userClient.auth.getUser()
///   if (error || !user) {
///     return new Response('Unauthorized', { status: 401, headers: corsHeaders })
///   }
///
///   // Delete with service role (admin privileges)
///   const adminClient = createClient(
///     Deno.env.get('SUPABASE_URL')!,
///     Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
///   )
///
///   // Note: The deployed edge function handles user_usage cleanup
///   // Add additional table cleanup here as needed:
///   // await adminClient.from('your_table').delete().eq('user_id', user.id)
///
///   const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)
///   if (deleteError) {
///     return new Response(deleteError.message, { status: 500, headers: corsHeaders })
///   }
///
///   return new Response(JSON.stringify({ success: true }), {
///     status: 200,
///     headers: { ...corsHeaders, 'Content-Type': 'application/json' }
///   })
/// })
/// ```
class SupabaseAuthProvider implements ISupabaseAuthProvider {
  GoTrueClient get _auth => Supabase.instance.client.auth;
  FunctionsClient get _functions => Supabase.instance.client.functions;

  /// Network timeout for auth operations (prevents indefinite hangs)
  static const _timeout = Duration(seconds: 30);

  /// Max retries for critical operations like session refresh
  static const _maxRetries = 3;

  /// Wrap async operations with timeout to prevent hanging
  Future<T> _withTimeout<T>(Future<T> operation) {
    return operation.timeout(
      _timeout,
      onTimeout: () => throw const AuthException('Request timed out'),
    );
  }

  /// Retry operation with exponential backoff (1s, 2s, 4s)
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    String? operationName,
  }) async {
    var lastError = const AuthException('Unknown error');
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on AuthException catch (e) {
        lastError = e;
        Log.warning('${operationName ?? 'Operation'} failed', {
          'attempt': attempt,
          'maxRetries': maxRetries,
          'error': e.message,
        });
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
          await Future<void>.delayed(delay);
        }
      }
    }
    throw lastError;
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Session? get currentSession => _auth.currentSession;

  /// Stream of auth state changes
  ///
  /// Emits on: sign-in, sign-out, token refresh, user update.
  /// Listen on app startup to handle session restoration.
  @override
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // ===========================================================================
  // OAuth / Native Sign In
  // ===========================================================================

  /// Sign in with ID token from native OAuth provider
  ///
  /// For Apple: [nonce] is the raw nonce (hashed version was sent to Apple SDK)
  /// For Google: [accessToken] recommended for additional user info access
  ///
  /// Throws [AuthException] on invalid token or provider mismatch.
  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) {
    return _withTimeout(_auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: nonce,
      accessToken: accessToken,
    ));
  }

  /// Sign in via browser-based OAuth flow
  ///
  /// Launches browser/webview for providers without native SDK (GitHub, Discord).
  /// Returns true if browser launched successfully.
  /// Auth result arrives via [onAuthStateChange] after redirect.
  ///
  /// [redirectTo] - Deep link URL to capture callback (required on mobile)
  /// [scopes] - Space-separated OAuth scopes (e.g., 'read:user user:email')
  @override
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) {
    return _auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      scopes: scopes,
      queryParams: queryParams,
    );
  }

  // ===========================================================================
  // Email / Password
  // ===========================================================================

  /// Sign in with email and password
  ///
  /// Throws [AuthException] with code 'invalid_credentials' on failure.
  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) {
    return _withTimeout(_auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    ));
  }

  /// Create new user account
  ///
  /// [data] - User metadata stored in user.user_metadata (e.g., name, avatar)
  ///
  /// User may need email confirmation depending on project settings.
  /// Check `response.user?.emailConfirmedAt` for confirmation status.
  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? captchaToken,
  }) {
    return _withTimeout(_auth.signUp(
      email: email,
      password: password,
      data: data,
      captchaToken: captchaToken,
    ));
  }

  /// Send password reset email
  ///
  /// [redirectTo] - Deep link to password reset screen in app.
  /// User clicks link, app receives token via deep link handler.
  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) {
    return _withTimeout(_auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
      captchaToken: captchaToken,
    ));
  }

  // ===========================================================================
  // Magic Link / OTP
  // ===========================================================================

  /// Send magic link email for passwordless sign-in
  ///
  /// [emailRedirectTo] - Deep link URL to capture callback (required on mobile).
  /// User clicks link in email, app receives session via deep link handler.
  @override
  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
    String? captchaToken,
  }) {
    return _withTimeout(_auth.signInWithOtp(
      email: email,
      emailRedirectTo: emailRedirectTo,
      captchaToken: captchaToken,
    ));
  }

  // ===========================================================================
  // Session Management
  // ===========================================================================

  /// Refresh current session tokens
  ///
  /// Call before token expiry for long-running operations.
  /// Supabase SDK handles automatic refresh, but manual refresh useful for:
  /// - App returning from background
  /// - Before critical API calls
  ///
  /// Throws [AuthException] if refresh token is invalid/expired after 3 retries.
  @override
  Future<AuthResponse> refreshSession() {
    return _withRetry(
      () => _withTimeout(_auth.refreshSession()),
      operationName: 'Session refresh',
    );
  }

  /// Restore session from refresh token
  ///
  /// Use for custom session persistence (e.g., secure storage).
  /// After calling, [currentUser] and [currentSession] will be populated.
  @override
  Future<AuthResponse> setSession(String refreshToken) {
    return _auth.setSession(refreshToken);
  }

  // ===========================================================================
  // User Management
  // ===========================================================================

  /// Update user email, password, or metadata
  ///
  /// Email changes may require re-confirmation depending on settings.
  @override
  Future<UserResponse> updateUser(UserAttributes attributes) {
    return _auth.updateUser(attributes);
  }

  /// Sign out and invalidate all sessions (not just local device)
  @override
  Future<void> signOut() {
    return _auth.signOut(scope: SignOutScope.global);
  }

  /// Delete user account via edge function
  ///
  /// Requires 'delete-user' edge function deployed with service-role access.
  /// Passes current access token for server-side user verification.
  ///
  /// Throws [FunctionException] on network/function errors.
  /// Caller should handle failure gracefully and sign out regardless.
  @override
  Future<void> deleteUser() async {
    Log.info('deleteUser: Starting');

    // 1. Refresh session to ensure fresh JWT
    try {
      await _auth.refreshSession();
      Log.info('deleteUser: Session refreshed');
    } on AuthException catch (e) {
      Log.warning('deleteUser: Session refresh failed', {'error': '$e'});
      // Continue anyway - current session might still be valid
    }

    // 2. Verify we have a session with access token
    final session = _auth.currentSession;
    if (session?.accessToken == null) {
      Log.error('deleteUser: No access token available');
      throw const AuthException('No access token available for user deletion');
    }
    Log.info('deleteUser: Session valid', {
      'userId': session!.user.id.substring(0, 8),
      'expiresAt': session.expiresAt?.toString() ?? 'unknown',
    });

    // 3. Call edge function with explicit Bearer token
    // Note: auth.headers does NOT include Bearer token, must construct explicitly
    Log.info('deleteUser: Invoking edge function');
    await _withTimeout(_functions.invoke(
      'delete-user',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    ));
    Log.info('deleteUser: Edge function completed');
  }

  /// Exchange Apple authorization code for refresh token
  ///
  /// Calls edge function to exchange the code and store the refresh token.
  /// Required for Apple compliance - tokens must be revoked on account delete.
  ///
  /// [accessToken] - Optional access token to use. If provided, bypasses session
  /// lookup which fixes timing issues when called immediately after sign-in.
  @override
  Future<void> exchangeAppleToken(
    String authorizationCode, {
    String? accessToken,
  }) async {
    // Use provided token or fall back to current session
    final token = accessToken ?? _auth.currentSession?.accessToken;
    if (token == null) {
      throw const AuthException('No access token for Apple token exchange');
    }

    // Call edge function with explicit Bearer token
    // Note: auth.headers does NOT include Bearer token, must construct explicitly
    await _withTimeout(_functions.invoke(
      'exchange-apple-token',
      headers: {'Authorization': 'Bearer $token'},
      body: {'authorization_code': authorizationCode},
    ));
  }

  /// Verify edge functions are deployed and responding
  ///
  /// Calls each function without auth - expects 401 Unauthorized (function exists)
  /// vs FunctionException with 'not found' (function not deployed).
  @override
  Future<Map<String, bool>> verifyEdgeFunctions() async {
    final functions = ['delete-user', 'exchange-apple-token'];
    final results = <String, bool>{};

    for (final name in functions) {
      try {
        // Call without auth - should return 401 if deployed
        await _functions.invoke(name).timeout(const Duration(seconds: 10));
        // If we get here without error, function exists (unexpected but ok)
        results[name] = true;
        Log.info('Edge function verified', {'function': name});
      } on FunctionException catch (e) {
        // 401/403 = function exists but auth required (expected)
        // 404 or 'not found' = function not deployed
        final reason = e.reasonPhrase?.toLowerCase() ?? '';
        final isDeployed = e.status == 401 ||
            e.status == 403 ||
            (e.status != 404 && !reason.contains('not found'));
        results[name] = isDeployed;

        if (isDeployed) {
          Log.info('Edge function verified', {'function': name});
        } else {
          Log.error('Edge function not deployed: $name (status: ${e.status})', e);
        }
      } on TimeoutException {
        // Timeout could mean function is slow but exists
        results[name] = false;
        Log.warning('Edge function timeout', {'function': name});
      } catch (e) {
        // Network error or other issue
        results[name] = false;
        Log.warning('Edge function check failed', {
          'function': name,
          'error': '$e',
        });
      }
    }

    // Log summary
    final allDeployed = results.values.every((v) => v);
    if (!allDeployed) {
      final missing =
          results.entries.where((e) => !e.value).map((e) => e.key).join(', ');
      Log.error('Missing edge functions: $missing - account deletion will fail');
    }

    return results;
  }

  // ===========================================================================
  // Multi-Factor Authentication (MFA)
  // ===========================================================================

  /// Enroll a new TOTP factor
  ///
  /// Returns QR code and secret for user to scan/enter in authenticator app.
  @override
  Future<AuthMFAEnrollResponse> mfaEnroll({String? friendlyName}) {
    return _withTimeout(_auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: friendlyName,
    ));
  }

  /// Create challenge for MFA verification
  @override
  Future<AuthMFAChallengeResponse> mfaChallenge(String factorId) {
    return _withTimeout(_auth.mfa.challenge(factorId: factorId));
  }

  /// Verify TOTP code
  ///
  /// Activates factor on first verification, upgrades session to aal2 on login.
  @override
  Future<AuthMFAVerifyResponse> mfaVerify({
    required String factorId,
    required String challengeId,
    required String code,
  }) {
    return _withTimeout(_auth.mfa.verify(
      factorId: factorId,
      challengeId: challengeId,
      code: code,
    ));
  }

  /// Remove an MFA factor
  @override
  Future<AuthMFAUnenrollResponse> mfaUnenroll(String factorId) {
    return _withTimeout(_auth.mfa.unenroll(factorId));
  }

  /// List all enrolled MFA factors
  @override
  Future<AuthMFAListFactorsResponse> mfaListFactors() async {
    return _auth.mfa.listFactors();
  }

  /// Get current AAL status
  ///
  /// Check if user needs to complete MFA challenge.
  @override
  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse>
      mfaGetAuthenticatorAssuranceLevel() async {
    return _auth.mfa.getAuthenticatorAssuranceLevel();
  }
}
