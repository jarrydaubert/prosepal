import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../interfaces/google_auth_provider.dart';

/// Real implementation of Google Sign In using native SDK (google_sign_in 7.x)
///
/// ## Breaking Changes in 7.x
/// The google_sign_in 7.x API introduced significant changes:
/// - [initialize] must be called exactly once before other methods
/// - [attemptLightweightAuthentication] replaces `signInSilently()`
/// - [authenticate] replaces `signIn()`
/// - Access tokens require explicit authorization via `authorizationClient`
///
/// ## Platform Configuration
/// - **Android**: Requires `serverClientId` (web client ID) for ID token retrieval.
///   Without google-services.json, this is essential.
/// - **iOS**: Requires `clientId` (iOS client ID) in addition to serverClientId.
/// - **Web**: Not supported by this native implementation. Use browser-based
///   OAuth flow via [ISupabaseAuthProvider.signInWithOAuth] instead.
///
/// ## Error Handling
/// [GoogleSignInException] is thrown on failures with these common codes:
/// - `canceled`: User cancelled the sign-in flow (returned as null, not thrown)
/// - `failed`: General failure (network, configuration, etc.)
/// - `networkError`: No network connectivity
/// - `unknownError`: Unexpected error
///
/// ## Token Notes
/// - ID token is retrieved from `user.authentication.idToken`
/// - Access token requires explicit scope authorization
/// - For long-lived sessions, tokens should be refreshed via Supabase
class GoogleAuthProvider implements IGoogleAuthProvider {
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Scopes configured during initialization
  List<String> _scopes = const ['email', 'profile'];

  /// Track initialization to prevent multiple calls
  bool _initialized = false;

  /// Initialize Google Sign In with client IDs
  ///
  /// **IMPORTANT**: Call exactly once before any authentication methods.
  /// Multiple calls are no-ops after first initialization.
  ///
  /// [serverClientId] - Web client ID from Google Cloud Console. Required for:
  ///   - Android ID token retrieval
  ///   - Backend token validation
  /// [clientId] - iOS client ID. Only applied on iOS platform.
  /// [scopes] - OAuth scopes to request (stored for later authorization).
  @override
  Future<void> initialize({
    required String? serverClientId,
    required String? clientId,
    List<String> scopes = const ['email', 'profile'],
  }) async {
    // Prevent multiple initializations (package recommendation)
    if (_initialized) return;

    _scopes = scopes;
    await _googleSignIn.initialize(
      serverClientId: serverClientId,
      clientId: Platform.isIOS ? clientId : null,
    );
    _initialized = true;
  }

  /// Check if Google Sign In is available on current platform
  ///
  /// Returns false for web (use browser OAuth instead) and unsupported platforms.
  /// Does not check configuration validity - that's detected during authentication.
  @override
  Future<bool> isAvailable() async {
    // Web requires different flow (Google Identity Services SDK)
    // This native implementation doesn't support web
    if (kIsWeb) return false;

    // Native SDK available on iOS and Android only
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Attempt silent re-authentication for returning users
  ///
  /// Returns null if no cached credentials exist (user never signed in
  /// or signed out). Does not show any UI.
  @override
  Future<GoogleAuthResult?> attemptLightweightAuthentication() async {
    final user = await _googleSignIn.attemptLightweightAuthentication();
    if (user == null) return null;
    return _toAuthResult(user);
  }

  /// Prompt user to sign in with Google
  ///
  /// Shows the Google Sign In UI. Returns null if user cancels.
  /// Throws [GoogleSignInException] on configuration or network errors.
  @override
  Future<GoogleAuthResult?> authenticate() async {
    try {
      final user = await _googleSignIn.authenticate();
      return _toAuthResult(user);
    } on GoogleSignInException catch (e) {
      // User cancelled - return null instead of throwing
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      // Rethrow configuration, network, and other errors
      rethrow;
    }
  }

  /// Request additional OAuth scopes for incremental authorization.
  ///
  /// Use for "just-in-time" authorization when user needs new API access.
  /// Returns null if user declines. Throws if not signed in.
  @override
  Future<GoogleAuthResult?> requestAdditionalScopes(List<String> scopes) async {
    final user = await _googleSignIn.attemptLightweightAuthentication();
    if (user == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'User not signed in',
      );
    }

    // Request incremental authorization
    final authorization = await user.authorizationClient.authorizeScopes(
      scopes,
    );

    // Combine with existing scopes
    _scopes = {..._scopes, ...scopes}.toList();

    return GoogleAuthResult(
      idToken: user.authentication.idToken,
      accessToken: authorization.accessToken,
      email: user.email,
      displayName: user.displayName,
    );
  }

  /// Sign out from Google (clears cached credentials)
  ///
  /// After sign out, [attemptLightweightAuthentication] will return null.
  /// User can still sign in again via [authenticate].
  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Disconnect and revoke all granted permissions
  ///
  /// Use for "unlink Google account" flows. User will need to
  /// re-authorize all scopes on next sign-in attempt.
  @override
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }

  /// Convert GoogleSignInAccount to our result type with tokens
  Future<GoogleAuthResult> _toAuthResult(GoogleSignInAccount user) async {
    // ID token from authentication (may be null in some edge cases)
    final idToken = user.authentication.idToken;

    // Access token requires explicit scope authorization
    // Try silent authorization first, fall back to interactive
    final authorization =
        await user.authorizationClient.authorizationForScopes(_scopes) ??
        await user.authorizationClient.authorizeScopes(_scopes);

    return GoogleAuthResult(
      idToken: idToken,
      accessToken: authorization.accessToken,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
