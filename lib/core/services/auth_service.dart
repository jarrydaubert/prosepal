import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/apple_auth_provider.dart';
import '../interfaces/auth_interface.dart';
import '../interfaces/google_auth_provider.dart';
import '../interfaces/supabase_auth_provider.dart';

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
        debugPrint('Google Sign-In pre-initialization failed: $e');
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
  Future<bool> isGoogleSignInAvailable() => _google.isAvailable();

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
    final name =
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user.email?.split('@').first;
    if (name != null && (user.email?.startsWith(name) ?? false)) {
      return name[0].toUpperCase() + name.substring(1);
    }
    return name;
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

      return await _supabase.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or authorization failed
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Apple Sign In cancelled');
      }
      throw AuthException('Apple Sign In failed: ${e.message}');
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
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
      throw const AuthException('Google Sign In cancelled');
    }

    final idToken = result.idToken;
    if (idToken == null) {
      throw const AuthException('Google Sign In failed: No ID token');
    }

    return _supabase.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: result.accessToken,
    );
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
      redirectTo: kIsWeb ? null : 'com.prosepal.prosepal://reset-callback',
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
      emailRedirectTo: kIsWeb ? null : 'com.prosepal.prosepal://login-callback',
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
    // Also sign out from Google to clear cached credentials
    try {
      await _google.signOut();
    } catch (_) {
      // Ignore - may not be signed in with Google
    }

    await _supabase.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Call edge function to delete user (requires admin/service role)
      await _supabase.deleteUser();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Account deletion error: $e');
        debugPrint(
          'Deploy the delete-user Edge Function in Supabase dashboard.',
        );
      }
      // Continue with sign-out even if deletion fails
      // User may need to contact support for full deletion
    }

    // Clear all local state and provider sessions
    try {
      await _google.disconnect(); // Revoke Google access
    } catch (_) {
      // Ignore - may not be signed in with Google
    }

    await _supabase.signOut();
  }
}
