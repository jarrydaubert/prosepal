import 'dart:async';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:prosepal/core/interfaces/apple_auth_provider.dart';

/// Mock implementation of IAppleAuthProvider for testing (sign_in_with_apple 7.x)
///
/// ## Usage
/// ```dart
/// final mockApple = MockAppleAuthProvider();
/// mockApple.credentialToReturn = createFakeAppleCredential();
/// final authService = AuthService(appleAuth: mockApple, ...);
///
/// await authService.signInWithApple();
/// expect(mockApple.getCredentialCalls, 1);
/// ```
///
/// ## Error Simulation
/// Use [errorToThrow] with [SignInWithAppleAuthorizationException] to test
/// cancellation vs error handling:
/// ```dart
/// mockApple.errorToThrow = SignInWithAppleAuthorizationException(
///   code: AuthorizationErrorCode.canceled,
///   message: 'User cancelled',
/// );
/// ```
///
/// ## Revocation Testing
/// The [onCredentialRevoked] stream is controllable via [emitCredentialRevoked].
/// Note: The real package (7.x) does not expose client-side revocation events.
/// Apple recommends server-side token validation for production revocation detection.
class MockAppleAuthProvider implements IAppleAuthProvider {
  /// Nonce to return from generateRawNonce()
  /// Default is 32 characters (recommended length for security)
  String nonceToReturn = 'test-nonce-1234567890123456789012';

  /// Value to return from isAvailable()
  bool isAvailableResult = true;

  /// Credential to return from getCredential()
  AuthorizationCredentialAppleID? credentialToReturn;

  /// Error to throw (if set, throws instead of returning)
  ///
  /// Use [SignInWithAppleAuthorizationException] for realistic error simulation:
  /// - AuthorizationErrorCode.canceled: User cancelled
  /// - AuthorizationErrorCode.failed: Authorization failed
  /// - AuthorizationErrorCode.invalidResponse: Invalid response from Apple
  /// - AuthorizationErrorCode.notHandled: Not handled
  /// - AuthorizationErrorCode.unknown: Unknown error
  Exception? errorToThrow;

  /// Controller for credential revocation events
  final _revocationController = StreamController<void>.broadcast();

  /// Track calls for verification
  int generateNonceCalls = 0;
  int isAvailableCalls = 0;
  int getCredentialCalls = 0;
  List<AppleIDAuthorizationScopes>? lastScopes;
  String? lastNonce;
  WebAuthenticationOptions? lastWebAuthOptions;
  String? lastState;
  int? lastNonceLength;

  @override
  String generateRawNonce([int length = 32]) {
    generateNonceCalls++;
    lastNonceLength = length;
    // Return configured nonce, truncated/padded to requested length if needed
    if (nonceToReturn.length >= length) {
      return nonceToReturn.substring(0, length);
    }
    return nonceToReturn.padRight(length, '0');
  }

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls++;
    return isAvailableResult;
  }

  @override
  Future<AuthorizationCredentialAppleID> getCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    required String nonce,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? state,
  }) async {
    getCredentialCalls++;
    lastScopes = scopes;
    lastNonce = nonce;
    lastWebAuthOptions = webAuthenticationOptions;
    lastState = state;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    if (credentialToReturn == null) {
      throw StateError(
        'MockAppleAuthProvider: credentialToReturn not set. '
        'Set it before calling getCredential().',
      );
    }

    return credentialToReturn!;
  }

  @override
  Stream<void> get onCredentialRevoked => _revocationController.stream;

  /// Emit a credential revocation event (for testing revocation handling)
  ///
  /// Note: Real sign_in_with_apple 7.x does not expose this stream.
  /// Use for testing theoretical revocation handling only.
  void emitCredentialRevoked() {
    _revocationController.add(null);
  }

  /// Simulate user cancellation (convenience method)
  void simulateCancellation() {
    errorToThrow = const SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.canceled,
      message: 'User cancelled',
    );
  }

  /// Simulate authorization failure (convenience method)
  void simulateAuthorizationFailure([String message = 'Authorization failed']) {
    errorToThrow = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.failed,
      message: message,
    );
  }

  /// Reset all state
  void reset() {
    nonceToReturn = 'test-nonce-1234567890123456789012';
    isAvailableResult = true;
    credentialToReturn = null;
    errorToThrow = null;
    generateNonceCalls = 0;
    isAvailableCalls = 0;
    getCredentialCalls = 0;
    lastScopes = null;
    lastNonce = null;
    lastWebAuthOptions = null;
    lastState = null;
    lastNonceLength = null;
  }

  void dispose() {
    _revocationController.close();
  }
}

/// Helper to create a fake Apple credential for testing
///
/// ## Field Notes (sign_in_with_apple 7.x)
/// - [userIdentifier]: Always provided, stable across sign-ins
/// - [givenName], [familyName], [email]: Only provided on FIRST sign-in,
///   null on subsequent sign-ins (Apple privacy feature)
/// - [authorizationCode]: Required, used for server-side token exchange
/// - [identityToken]: JWT containing user info, required for Supabase auth
///
/// ## Failure Simulation
/// Use [withNullIdentityToken] = true to simulate missing identity token error
AuthorizationCredentialAppleID createFakeAppleCredential({
  String userIdentifier = 'apple-user-123',
  String? givenName,
  String? familyName,
  String? email,
  String authorizationCode = 'auth-code-xyz',
  String? identityToken = 'valid-id-token-abc123',
  String? state,
  bool withNullIdentityToken = false,
}) {
  return AuthorizationCredentialAppleID(
    userIdentifier: userIdentifier,
    givenName: givenName,
    familyName: familyName,
    email: email,
    authorizationCode: authorizationCode,
    identityToken: withNullIdentityToken ? null : identityToken,
    state: state,
  );
}

/// Create a credential simulating first-time sign-in (includes name/email)
AuthorizationCredentialAppleID createFakeAppleCredentialFirstSignIn({
  String userIdentifier = 'apple-user-123',
  String givenName = 'John',
  String familyName = 'Doe',
  String email = 'john.doe@privaterelay.appleid.com',
  String authorizationCode = 'auth-code-xyz',
  String identityToken = 'valid-id-token-abc123',
  String? state,
}) {
  return AuthorizationCredentialAppleID(
    userIdentifier: userIdentifier,
    givenName: givenName,
    familyName: familyName,
    email: email,
    authorizationCode: authorizationCode,
    identityToken: identityToken,
    state: state,
  );
}
