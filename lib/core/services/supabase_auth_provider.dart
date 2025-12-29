import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/supabase_auth_provider.dart';

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
///   // TODO: Clean up user data before deleting auth user
///   // await adminClient.from('saved_messages').delete().eq('user_id', user.id)
///   // await adminClient.from('user_preferences').delete().eq('user_id', user.id)
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
    return _auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: nonce,
      accessToken: accessToken,
    );
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
    return _auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );
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
    return _auth.signUp(
      email: email,
      password: password,
      data: data,
      captchaToken: captchaToken,
    );
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
    return _auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
      captchaToken: captchaToken,
    );
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
    return _auth.signInWithOtp(
      email: email,
      emailRedirectTo: emailRedirectTo,
      captchaToken: captchaToken,
    );
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
  /// Throws [AuthException] if refresh token is invalid/expired.
  @override
  Future<AuthResponse> refreshSession() {
    return _auth.refreshSession();
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

  /// Sign out and clear local session
  @override
  Future<void> signOut() {
    return _auth.signOut();
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
    final accessToken = _auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw const AuthException('No active session for user deletion');
    }

    // Pass access token for server-side verification
    // Edge function validates token and extracts user ID
    await _functions.invoke(
      'delete-user',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}
