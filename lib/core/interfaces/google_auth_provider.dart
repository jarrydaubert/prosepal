/// Represents a Google user's authentication result
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    required this.accessToken,
    this.email,
    this.displayName,
  });

  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
}

/// Interface for Google Sign In operations
/// Allows mocking native SDK calls in tests
abstract class IGoogleAuthProvider {
  /// Initialize Google Sign In with client IDs
  ///
  /// [serverClientId] - Web client ID from Google Cloud Console, required for
  /// ID token retrieval on Android. Used for backend token validation.
  /// [clientId] - iOS client ID, only used on iOS platform.
  /// [scopes] - OAuth scopes to request (defaults to email, profile).
  Future<void> initialize({
    required String? serverClientId,
    required String? clientId,
    List<String> scopes = const ['email', 'profile'],
  });

  /// Check if Google Sign In is available on current platform
  ///
  /// Returns false on platforms where Google Sign In is not supported
  /// or not properly configured.
  Future<bool> isAvailable();

  /// Attempt silent/lightweight authentication (previously signed in user)
  ///
  /// Returns null if no previous session exists. Does not prompt user.
  /// Use this on app startup to restore existing sessions silently.
  Future<GoogleAuthResult?> attemptLightweightAuthentication();

  /// Prompt user to sign in with Google
  ///
  /// Returns null if user cancels the sign-in flow.
  /// Throws [Exception] on genuine failures (network, configuration, etc).
  ///
  /// Note: User cancellation is treated as non-error (returns null) rather
  /// than throwing, allowing callers to distinguish cancellation from failure.
  Future<GoogleAuthResult?> authenticate();

  /// Sign out from Google (clears local session)
  ///
  /// Does not revoke access - user can still sign in silently next time.
  /// Use [disconnect] to fully revoke access.
  Future<void> signOut();

  /// Disconnect and revoke access
  ///
  /// Revokes all granted permissions. User will need to re-authorize
  /// on next sign-in attempt. Use for "unlink account" flows.
  Future<void> disconnect();
}
