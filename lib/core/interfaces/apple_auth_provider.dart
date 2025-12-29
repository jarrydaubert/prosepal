import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Interface for Apple Sign In operations
/// Allows mocking native SDK calls in tests
abstract class IAppleAuthProvider {
  /// Generate a cryptographically secure raw nonce
  ///
  /// Returns a random string (default 32 chars) using URL-safe characters.
  /// The raw nonce should be SHA-256 hashed before passing to [getCredential],
  /// while the raw value is sent to Supabase for token validation.
  String generateRawNonce([int length = 32]);

  /// Check if Sign in with Apple is available on current platform
  ///
  /// Returns false on Android/Windows/Linux where Apple Sign In is unsupported.
  /// Always check before showing Apple Sign In button.
  Future<bool> isAvailable();

  /// Get Apple ID credential via native SDK
  ///
  /// [scopes] - Request email and/or fullName (only provided on first auth)
  /// [nonce] - SHA-256 hashed nonce for replay attack prevention
  /// [webAuthenticationOptions] - Required for web platform (clientId, redirectUri)
  /// [state] - Optional state parameter for OAuth flow
  ///
  /// Throws [SignInWithAppleAuthorizationException] on failure/cancellation
  Future<AuthorizationCredentialAppleID> getCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    required String nonce,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? state,
  });

  /// Stream of credential revocation events (iOS/macOS only)
  ///
  /// Fires when user revokes app access in Apple ID settings.
  /// Listen to this and sign out user when event received.
  Stream<void> get onCredentialRevoked;
}
