import 'package:google_sign_in/google_sign_in.dart';

/// Represents a Google user's authentication result.
///
/// ## Authentication vs Authorization (google_sign_in 7.x)
/// - [idToken] comes from **authentication** - proves user identity
/// - [accessToken] comes from **authorization** - grants API access
///
/// The google_sign_in 7.x package separates these concerns:
/// - Authentication: User signs in, we get idToken for backend validation
/// - Authorization: User grants scope permissions, we get accessToken for APIs
///
/// For Supabase auth, only [idToken] is required. The [accessToken] is only
/// needed if calling Google APIs directly (Drive, Calendar, etc.).
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
  });

  /// JWT token for backend identity verification (from authentication).
  /// Pass this to Supabase `signInWithIdToken()` for user authentication.
  final String? idToken;

  /// OAuth access token for Google API calls (from authorization).
  /// Only present if scopes were requested and authorized.
  /// Note: Access tokens expire - use [requestAdditionalScopes] to refresh.
  final String? accessToken;

  /// User's email address (may be null if email scope not granted).
  final String? email;

  /// User's display name (may be null if profile scope not granted).
  final String? displayName;
}

/// Interface for Google Sign In operations (google_sign_in 7.x).
///
/// Allows mocking native SDK calls in tests. Implements the v7.x pattern
/// that separates authentication (identity) from authorization (API access).
///
/// ## Usage Flow
/// 1. Call [initialize] once at app startup
/// 2. Check [isAvailable] before showing Google Sign In button
/// 3. Try [attemptLightweightAuthentication] for returning users
/// 4. Use [authenticate] for new sign-ins
/// 5. If needed, use [requestAdditionalScopes] for extra API access
///
/// ## Error Handling
/// Methods may throw [GoogleSignInException] with these codes:
/// - [GoogleSignInExceptionCode.canceled] - User cancelled (handled as null return)
/// - [GoogleSignInExceptionCode.interrupted] - Flow interrupted
/// - [GoogleSignInExceptionCode.clientConfigurationError] - Missing client ID
/// - [GoogleSignInExceptionCode.providerConfigurationError] - SDK misconfigured
/// - [GoogleSignInExceptionCode.uiUnavailable] - Cannot show sign-in UI
/// - [GoogleSignInExceptionCode.unknownError] - Other failures
///
/// ## Platform Support
/// - iOS: Full native support (requires clientId)
/// - Android: Full native support (requires serverClientId)
/// - Web: Not supported by native SDK - use Supabase OAuth instead
abstract class IGoogleAuthProvider {
  /// Initialize Google Sign In with client IDs.
  ///
  /// **Must be called exactly once** before any other methods.
  /// Subsequent calls are no-ops.
  ///
  /// [serverClientId] - Web client ID from Google Cloud Console.
  ///   Required for Android ID token retrieval and backend validation.
  /// [clientId] - iOS client ID from Google Cloud Console.
  ///   Only applied on iOS platform.
  /// [scopes] - OAuth scopes for initial authorization.
  ///   Defaults to ['email', 'profile'] for basic user info.
  ///
  /// Throws [GoogleSignInException] with [clientConfigurationError] if
  /// required client IDs are missing for the current platform.
  Future<void> initialize({
    required String? serverClientId,
    required String? clientId,
    List<String> scopes = const ['email', 'profile'],
  });

  /// Check if Google Sign In is available on current platform.
  ///
  /// Returns false for:
  /// - Web (use Supabase OAuth instead)
  /// - Platforms without Google Play Services (some Android)
  /// - Unsupported platforms (Linux, Windows desktop)
  ///
  /// Note: This doesn't validate configuration - configuration errors
  /// are detected during [authenticate].
  Future<bool> isAvailable();

  /// Attempt silent re-authentication for returning users.
  ///
  /// Returns cached credentials if user previously signed in and hasn't
  /// signed out. Does not show any UI.
  ///
  /// Returns null if:
  /// - User never signed in
  /// - User signed out
  /// - Cached session expired
  ///
  /// Use on app startup before showing sign-in UI.
  Future<GoogleAuthResult?> attemptLightweightAuthentication();

  /// Prompt user to sign in with Google.
  ///
  /// Shows the native Google Sign In UI. Returns [GoogleAuthResult] on success
  /// with [idToken] for backend authentication.
  ///
  /// Returns null if user cancels the flow (not an error).
  ///
  /// Throws [GoogleSignInException] on failures:
  /// - Network errors
  /// - Configuration errors
  /// - Platform issues
  Future<GoogleAuthResult?> authenticate();

  /// Request additional OAuth scopes after initial sign-in.
  ///
  /// Use this to incrementally request API access (e.g., Drive, Calendar)
  /// when the user needs that feature, rather than requesting all scopes
  /// upfront. This follows Google's recommended "just-in-time" authorization.
  ///
  /// [scopes] - Additional OAuth scopes to request.
  ///   See: https://developers.google.com/identity/protocols/oauth2/scopes
  ///
  /// Returns new [GoogleAuthResult] with updated [accessToken] for the
  /// combined scopes, or null if user declines.
  ///
  /// Throws [GoogleSignInException] if user is not signed in.
  Future<GoogleAuthResult?> requestAdditionalScopes(List<String> scopes);

  /// Sign out from Google (clears local session).
  ///
  /// After sign out:
  /// - [attemptLightweightAuthentication] returns null
  /// - User can still sign in again via [authenticate]
  /// - Previously granted permissions remain valid
  ///
  /// Use [disconnect] to also revoke permissions.
  Future<void> signOut();

  /// Disconnect and revoke all granted permissions.
  ///
  /// Use for "unlink Google account" flows. After disconnect:
  /// - All granted scopes are revoked
  /// - User must re-authorize everything on next sign-in
  /// - Google account is fully unlinked from app
  Future<void> disconnect();
}
