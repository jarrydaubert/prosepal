import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/apple_auth_provider.dart';
import '../interfaces/auth_interface.dart';
import '../interfaces/google_auth_provider.dart';
import '../interfaces/supabase_auth_provider.dart';
import 'log_service.dart';

// ===========================================================================
// Deep Link Scheme - must match iOS/Android URL scheme configuration
// ===========================================================================
const _deepLinkScheme = 'com.prosepal.prosepal';

// ===========================================================================
// Google OAuth Client IDs - configured in Google Cloud Console
// ===========================================================================
// GOOGLE_WEB_CLIENT_ID: Web client ID, required for:
//   - Android: ID token retrieval (if not using google-services.json)
//   - Web: Browser-based OAuth flow
//   - Backend: Token validation with Google's servers
//
// GOOGLE_IOS_CLIENT_ID: iOS client ID, required for:
//   - iOS: Native Sign In With Google SDK
//   - Set in GoogleService-Info.plist CLIENT_ID field
//
// Pass via dart-define: --dart-define=GOOGLE_WEB_CLIENT_ID=xxx
// ===========================================================================
const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const _googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// Validates that required Google client IDs are configured.
/// Returns true if Google Sign-In can work, false otherwise.
bool _validateGoogleClientIds() {
  if (_googleWebClientId.isEmpty) {
    Log.warning(
      'GOOGLE_WEB_CLIENT_ID not configured - Google Sign-In disabled',
      {'hint': 'Pass via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx'},
    );
    return false;
  }
  return true;
}

/// Authentication service using dependency injection for testability
///
/// Supports Apple Sign-In, Google OAuth, and email/magic link flows.
/// All external dependencies are injected via constructor.
///
/// ## Usage
/// ```dart
/// final authService = AuthService(
///   supabaseAuth: SupabaseAuthProvider(),
///   appleAuth: AppleAuthProvider(),
///   googleAuth: GoogleAuthProvider(),
/// );
///
/// // Check availability before showing buttons
/// if (await authService.isAppleSignInAvailable()) {
///   // Show Apple Sign In button
/// }
/// ```
///
/// ## Environment Variables
/// - `GOOGLE_WEB_CLIENT_ID`: Web client ID for Android/Web token retrieval
/// - `GOOGLE_IOS_CLIENT_ID`: iOS client ID for native SDK
class AuthService implements IAuthService {
  AuthService({
    required ISupabaseAuthProvider supabaseAuth,
    required IAppleAuthProvider appleAuth,
    required IGoogleAuthProvider googleAuth,
  }) : _supabase = supabaseAuth,
       _apple = appleAuth,
       _google = googleAuth;

  final ISupabaseAuthProvider _supabase;
  final IAppleAuthProvider _apple;
  final IGoogleAuthProvider _google;

  bool _providersInitialized = false;

  // ===========================================================================
  // Provider Initialization
  // ===========================================================================

  /// Initialize OAuth providers at app startup
  ///
  /// Call once during app initialization for faster sign-in UX.
  /// Initializes Google Sign-In SDK with client IDs - subsequent
  /// sign-in attempts will be faster as SDK is pre-warmed.
  @override
  Future<void> initializeProviders() async {
    if (_providersInitialized) return;

    // Initialize Google Sign-In if available
    if (await _google.isAvailable()) {
      try {
        await _google.initialize(
          serverClientId: _googleWebClientId,
          clientId: _googleIosClientId,
        );
      } catch (e) {
        // Non-fatal: sign-in will still work, just slower on first attempt
        Log.warning('Google Sign-In pre-initialization failed', {
          'error': '$e',
        });
      }
    }

    _providersInitialized = true;
  }

  // ===========================================================================
  // Platform Availability
  // ===========================================================================

  /// Check if Apple Sign In is available on current platform
  ///
  /// Returns false on Android, Windows, Linux where Apple Sign In is unsupported.
  /// Use this to conditionally show/hide the Apple Sign In button.
  Future<bool> isAppleSignInAvailable() => _apple.isAvailable();

  /// Check if Google Sign In is available on current platform
  ///
  /// Returns false if not properly configured or on unsupported platforms.
  /// Also validates that required client IDs are configured.
  Future<bool> isGoogleSignInAvailable() async {
    if (!_validateGoogleClientIds()) return false;
    return _google.isAvailable();
  }

  @override
  User? get currentUser => _supabase.currentUser;

  @override
  bool get isLoggedIn => currentUser != null;

  @override
  Stream<AuthState> get authStateChanges => _supabase.onAuthStateChange;

  @override
  String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;

    // Prefer provider-supplied name, fall back to email username
    final rawName =
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user.email?.split('@').first;

    if (rawName == null || rawName.isEmpty) return null;

    // Capitalize each word for consistent display
    return rawName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  String? get email => currentUser?.email;

  // ===========================================================================
  // OAuth Sign In
  // ===========================================================================

  /// SHA256 hash for nonce (required for Apple Sign In security)
  ///
  /// The raw nonce is sent to Supabase for token validation, while
  /// the hashed nonce is sent to Apple SDK to prevent replay attacks.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<AuthResponse> signInWithApple() async {
    Log.info('Sign in started', {'provider': 'apple'});

    // Check platform availability first
    if (!await _apple.isAvailable()) {
      throw const AuthException(
        'Apple Sign In is not available on this platform',
      );
    }

    try {
      // Generate nonce for replay attack prevention
      final rawNonce = _apple.generateRawNonce();
      final hashedNonce = sha256ofString(rawNonce);

      final credential = await _apple.getCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple Sign In failed: No identity token');
      }

      final response = await _supabase.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Exchange authorization code for refresh token (for revocation on delete)
      // Must happen immediately as code expires in 5 minutes
      // Pass access token directly to avoid timing issues (session may not be persisted yet)
      final authCode = credential.authorizationCode;
      final accessToken = response.session?.accessToken;
      if (accessToken != null) {
        // Fire and forget - don't block sign-in flow
        unawaited(
          _supabase
              .exchangeAppleToken(authCode, accessToken: accessToken)
              .catchError((e) {
            // Non-fatal: revocation will be skipped if exchange fails
            Log.warning('Failed to exchange Apple authorization code', {
              'error': '$e',
            });
          }),
        );
      }

      Log.info('User signed in', {'provider': 'apple'});
      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or authorization failed
      if (e.code == AuthorizationErrorCode.canceled) {
        Log.info('Sign in cancelled', {'provider': 'apple'});
        throw const AuthException('Apple Sign In cancelled');
      }
      Log.warning('Sign in failed', {'provider': 'apple', 'error': e.message});
      throw AuthException('Apple Sign In failed: ${e.message}');
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    Log.info('Sign in started', {'provider': 'google'});

    // Check platform availability first
    if (!await _google.isAvailable()) {
      throw const AuthException(
        'Google Sign In is not available on this platform',
      );
    }

    // Ensure initialized (no-op if already done at startup)
    if (!_providersInitialized) {
      await _google.initialize(
        serverClientId: _googleWebClientId,
        clientId: _googleIosClientId,
      );
    }

    // Try silent re-auth first (better UX for returning users)
    var result = await _google.attemptLightweightAuthentication();

    // If no cached session, prompt user
    result ??= await _google.authenticate();

    // User cancelled sign-in (authenticate returns null on cancel)
    if (result == null) {
      Log.info('Sign in cancelled', {'provider': 'google'});
      throw const AuthException('Google Sign In cancelled');
    }

    final idToken = result.idToken;
    if (idToken == null) {
      Log.warning('Sign in failed', {
        'provider': 'google',
        'error': 'No ID token',
      });
      throw const AuthException('Google Sign In failed: No ID token');
    }

    final response = await _supabase.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: result.accessToken,
    );

    Log.info('User signed in', {'provider': 'google'});
    return response;
  }

  // ===========================================================================
  // Email / Password Authentication
  // ===========================================================================

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.signUp(email: email, password: password);
  }

  @override
  Future<void> resetPassword(String email) async {
    // Use deep link to handle password reset in app
    await _supabase.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : '$_deepLinkScheme://reset-callback',
    );
  }

  // ===========================================================================
  // Magic Link (Passwordless)
  // ===========================================================================

  @override
  Future<void> signInWithMagicLink(String email) async {
    // Deep link required for mobile to capture auth callback
    await _supabase.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? null : '$_deepLinkScheme://login-callback',
    );
  }

  // ===========================================================================
  // User Management
  // ===========================================================================

  @override
  Future<void> updateEmail(String newEmail) async {
    await _supabase.updateUser(UserAttributes(email: newEmail));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    Log.info('Sign out initiated');

    // Also sign out from Google to clear cached credentials
    try {
      await _google.signOut();
    } catch (_) {
      // Ignore - may not be signed in with Google
    }

    await _supabase.signOut();
    Log.info('User signed out');
    Log.clearBuffer(); // Clear logs on sign out for privacy
  }

  @override
  Future<void> deleteAccount() async {
    Log.info('Delete account initiated');

    final user = currentUser;
    if (user == null) {
      throw const AuthException('No user signed in');
    }

    // Call edge function to delete user (requires admin/service role)
    // Note: deleteUser() internally refreshes the session for fresh JWT
    // This MUST succeed before we proceed - do not sign out on failure
    try {
      await _supabase.deleteUser();
      Log.info('Account deleted from server');
    } catch (e, stackTrace) {
      Log.error('Account deletion failed', e, stackTrace, {
        'hint': 'Ensure delete-user Edge Function is deployed in Supabase',
      });
      // Rethrow - caller must handle this and inform user
      throw AuthException(
        'Failed to delete account. Please try again or contact support.',
      );
    }

    // Server deletion succeeded - now clean up local state
    try {
      await _google.disconnect(); // Revoke Google access
    } catch (_) {
      // Non-fatal: may not be signed in with Google
    }

    await _supabase.signOut();
    Log.clearBuffer(); // Clear logs for privacy
    Log.info('Delete account completed');
  }
}
