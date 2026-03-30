import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/preference_keys.dart';
import '../interfaces/apple_auth_provider.dart';
import '../interfaces/auth_interface.dart';
import '../interfaces/google_auth_provider.dart';
import '../interfaces/supabase_auth_provider.dart';
import 'log_service.dart';

/// Validates that required Google client IDs are configured.
/// Returns true if Google Sign-In can work, false otherwise.
bool _validateGoogleClientIds() {
  if (AppConfig.googleWebClientId.isEmpty) {
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
/// Supports Apple Sign-In and Google OAuth (social-only).
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
    SharedPreferences? preferences,
    List<Duration> appleTokenExchangeRetryDelays = const [
      Duration(milliseconds: 300),
      Duration(milliseconds: 900),
    ],
  }) : _supabase = supabaseAuth,
       _apple = appleAuth,
       _google = googleAuth,
       _preferences = preferences,
       _appleTokenExchangeRetryDelays = appleTokenExchangeRetryDelays;

  final ISupabaseAuthProvider _supabase;
  final IAppleAuthProvider _apple;
  final IGoogleAuthProvider _google;
  final SharedPreferences? _preferences;
  final List<Duration> _appleTokenExchangeRetryDelays;

  bool _providersInitialized = false;
  String? _pendingPostSignInNotice;

  static final Map<String, Object?> _memoryFallback = <String, Object?>{};
  static const _appleDeleteBlockedMessage =
      'Account deletion is temporarily unavailable because Apple Sign In '
      'token recovery did not finish. Please contact support from '
      'Settings > Send Feedback and mention Apple token recovery.';
  static const _appleRecoveryNotice =
      'Apple Sign In worked, but delete-account recovery needs support '
      'attention on this device. If you need to delete your account, use '
      'Settings > Send Feedback and mention Apple token recovery.';

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
          serverClientId: AppConfig.googleWebClientId,
          clientId: AppConfig.googleIosClientId,
        );
      } on Exception catch (e) {
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
  Future<String?> consumePostSignInNotice() async {
    final inMemoryNotice = _pendingPostSignInNotice;
    _pendingPostSignInNotice = null;
    if (inMemoryNotice != null) return inMemoryNotice;

    final userId = currentUser?.id;
    if (userId == null) return null;
    return await _hasAppleTokenRecoveryPending(userId)
        ? _appleRecoveryNotice
        : null;
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

      // Exchange authorization code for refresh token (required for account deletion)
      // Must happen immediately as Apple auth codes expire in 5 minutes
      // Pass access token directly to avoid timing issues (session may not be persisted yet)
      // CRITICAL: Awaited to ensure token is stored - required for App Store compliance
      final authCode = credential.authorizationCode;
      final accessToken = response.session?.accessToken;
      final signedInUserId = response.user?.id ?? _supabase.currentUser?.id;
      if (signedInUserId != null) {
        await _completeAppleTokenExchangeRecovery(
          authorizationCode: authCode,
          accessToken: accessToken,
          userId: signedInUserId,
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
        serverClientId: AppConfig.googleWebClientId,
        clientId: AppConfig.googleIosClientId,
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

    // Note: google_sign_in 7.x on iOS includes a nonce in the ID token.
    // Enable "Skip nonce checks" for Google in Supabase Dashboard to fix
    // "Nonces mismatch" error, since we can't access the raw nonce.
    final response = await _supabase.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: result.accessToken,
    );

    Log.info('User signed in', {'provider': 'google'});
    return response;
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
    } on Exception catch (e) {
      // Expected if user wasn't signed in with Google
      Log.info('Google sign-out skipped', {'reason': '$e'});
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

    if (await _hasAppleTokenRecoveryPending(user.id)) {
      Log.warning('Delete account blocked by pending Apple token recovery', {
        'userId': _truncateUserId(user.id),
      });
      throw const AuthException(_appleDeleteBlockedMessage);
    }

    // Call edge function to delete user (requires admin/service role)
    // Note: deleteUser() internally refreshes the session for fresh JWT
    // This MUST succeed before we proceed - do not sign out on failure
    try {
      await _supabase.deleteUser();
      Log.info('Account deleted from server');
    } on Exception catch (e, stackTrace) {
      Log.error('Account deletion failed', e, stackTrace, {
        'hint': 'Ensure delete-user Edge Function is deployed in Supabase',
      });
      // Rethrow - caller must handle this and inform user
      throw const AuthException(
        'Failed to delete account. Please try again or contact support.',
      );
    }

    // Server deletion succeeded - now clean up local state
    try {
      await _google.disconnect(); // Revoke Google access
    } on Exception catch (_) {
      // Non-fatal: may not be signed in with Google
    }

    await _clearAppleTokenRecoveryPending(user.id);
    await _supabase.signOut();
    Log.clearBuffer(); // Clear logs for privacy
    Log.info('Delete account completed');
  }

  Future<void> _completeAppleTokenExchangeRecovery({
    required String authorizationCode,
    required String? accessToken,
    required String userId,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      await _markAppleTokenRecoveryPending(userId);
      _pendingPostSignInNotice = _appleRecoveryNotice;
      Log.error(
        'Apple token exchange unavailable - missing access token',
        null,
        null,
        {'userId': _truncateUserId(userId)},
      );
      return;
    }

    final attemptCount = _appleTokenExchangeRetryDelays.length + 1;
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt < attemptCount; attempt++) {
      try {
        await _supabase.exchangeAppleToken(
          authorizationCode,
          accessToken: accessToken,
        );
        await _clearAppleTokenRecoveryPending(userId);
        Log.info('Apple token exchange successful', {
          'attempt': attempt + 1,
          'userId': _truncateUserId(userId),
        });
        return;
      } on Exception catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        final isLastAttempt = attempt == attemptCount - 1;
        Log.warning('Apple token exchange attempt failed', {
          'attempt': attempt + 1,
          'attempts': attemptCount,
          'error': '$error',
          'userId': _truncateUserId(userId),
        });
        if (!isLastAttempt) {
          await Future<void>.delayed(_appleTokenExchangeRetryDelays[attempt]);
        }
      }
    }

    await _markAppleTokenRecoveryPending(userId);
    _pendingPostSignInNotice = _appleRecoveryNotice;
    Log.error(
      'Apple token exchange failed after retries - delete compliance blocked',
      lastError,
      lastStackTrace,
      {'attempts': attemptCount, 'userId': _truncateUserId(userId)},
    );
  }

  Future<bool> _hasAppleTokenRecoveryPending(String userId) async {
    final key = _appleTokenRecoveryKey(userId);
    return (_preferences?.getBool(key) ?? _memoryFallback[key] as bool?) ??
        false;
  }

  Future<void> _markAppleTokenRecoveryPending(String userId) async {
    final key = _appleTokenRecoveryKey(userId);
    if (_preferences != null) {
      await _preferences.setBool(key, true);
    } else {
      _memoryFallback[key] = true;
    }
  }

  Future<void> _clearAppleTokenRecoveryPending(String userId) async {
    final key = _appleTokenRecoveryKey(userId);
    if (_preferences != null) {
      await _preferences.remove(key);
    } else {
      _memoryFallback.remove(key);
    }
  }

  static String _appleTokenRecoveryKey(String userId) =>
      '${PreferenceKeys.appleTokenRecoveryPendingPrefix}$userId';

  static String _truncateUserId(String userId) =>
      userId.length <= 8 ? userId : userId.substring(0, 8);
}
