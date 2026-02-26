import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    as apple
    show
        SignInWithApple,
        AuthorizationCredentialAppleID,
        AppleIDAuthorizationScopes,
        WebAuthenticationOptions,
        generateNonce;

import '../interfaces/apple_auth_provider.dart';

/// Real implementation of Apple Sign In using native SDK (sign_in_with_apple 7.x)
///
/// ## Security Notes
/// - The nonce returned by [generateRawNonce] must be SHA-256 hashed before
///   passing to [getCredential]. The raw nonce is then sent to Supabase for
///   token validation. See [AuthService.signInWithApple] for correct usage.
/// - [getCredential] throws [SignInWithAppleAuthorizationException] on
///   failure or user cancellation. Callers should handle cancellation
///   (AuthorizationErrorCode.canceled) as non-error where appropriate.
///
/// ## Platform Support
/// - iOS: Full native support via ASAuthorizationController
/// - macOS: Full native support
/// - Android: Not supported (isAvailable returns false)
/// - Web: Requires webAuthenticationOptions with clientId and redirectUri
///
/// ## Credential Revocation
/// Apple recommends server-side token validation for detecting revocations.
/// The sign_in_with_apple package does not expose client-side revocation.
/// Implement server-side checks via Apple webhooks if needed.
class AppleAuthProvider implements IAppleAuthProvider {
  /// Generate cryptographically secure random nonce
  ///
  /// Uses `Random.secure()` internally (via sign_in_with_apple package) for
  /// OWASP-compliant cryptographic randomness. Returns URL-safe string.
  ///
  /// Caller must SHA-256 hash this value before passing to [getCredential],
  /// while sending the raw value to Supabase for token validation.
  @override
  String generateRawNonce([int length = 32]) =>
      apple.generateNonce(length: length);

  /// Check if Sign in with Apple is available on current platform
  ///
  /// Returns false on Android, Windows, Linux. Always check before
  /// showing Apple Sign In button to avoid runtime errors.
  @override
  Future<bool> isAvailable() => apple.SignInWithApple.isAvailable();

  /// Request Apple ID credential via native SDK
  ///
  /// [nonce] should be SHA-256 hashed value (not raw) for security.
  /// Throws [SignInWithAppleAuthorizationException] on failure/cancellation.
  @override
  Future<apple.AuthorizationCredentialAppleID> getCredential({
    required List<apple.AppleIDAuthorizationScopes> scopes,
    required String nonce,
    apple.WebAuthenticationOptions? webAuthenticationOptions,
    String? state,
  }) => apple.SignInWithApple.getAppleIDCredential(
    scopes: scopes,
    nonce: nonce,
    webAuthenticationOptions: webAuthenticationOptions,
    state: state,
  );
}
