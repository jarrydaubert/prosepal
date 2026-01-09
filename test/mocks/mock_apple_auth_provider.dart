import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:prosepal/core/interfaces/apple_auth_provider.dart';

/// Mock implementation of IAppleAuthProvider for testing
///
/// Designed for sign_in_with_apple 7.x (tested with v7.0.1).
/// Updates to error codes or API should be verified against package changelog.
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
/// Use convenience methods or set [errorToThrow] directly:
/// ```dart
/// // Convenience method:
/// mockApple.simulateCancellation();
///
/// // Direct exception:
/// mockApple.errorToThrow = SignInWithAppleAuthorizationException(
///   code: AuthorizationErrorCode.failed,
///   message: 'Keychain error',
/// );
/// ```
///
/// ## Apple Privacy Model
/// Use [createFakeAppleCredentialFirstSignIn] for first sign-in (includes name/email)
/// and [createFakeAppleCredential] for subsequent sign-ins (null name/email).
class MockAppleAuthProvider implements IAppleAuthProvider {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Nonce to return from generateRawNonce()
  /// Default is 32 characters (recommended length for security)
  @visibleForTesting
  String nonceToReturn = 'test-nonce-1234567890123456789012';

  /// Value to return from isAvailable()
  @visibleForTesting
  bool isAvailableResult = true;

  /// Credential to return from getCredential()
  @visibleForTesting
  AuthorizationCredentialAppleID? credentialToReturn;

  /// Error to throw (if set, throws instead of returning)
  ///
  /// Use [SignInWithAppleAuthorizationException] for realistic error simulation.
  /// See convenience methods: [simulateCancellation], [simulateAuthorizationFailure],
  /// [simulateNotHandled], [simulateInvalidResponse], [simulateUnknownError].
  @visibleForTesting
  Exception? errorToThrow;

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times generateRawNonce() was called
  @visibleForTesting
  int generateNonceCalls = 0;

  /// Number of times isAvailable() was called
  @visibleForTesting
  int isAvailableCalls = 0;

  /// Number of times getCredential() was called
  @visibleForTesting
  int getCredentialCalls = 0;

  /// Last scopes passed to getCredential()
  @visibleForTesting
  List<AppleIDAuthorizationScopes>? lastScopes;

  /// Last nonce passed to getCredential()
  @visibleForTesting
  String? lastNonce;

  /// Last webAuthenticationOptions passed to getCredential()
  @visibleForTesting
  WebAuthenticationOptions? lastWebAuthOptions;

  /// Last state passed to getCredential()
  @visibleForTesting
  String? lastState;

  /// Last length passed to generateRawNonce()
  @visibleForTesting
  int? lastNonceLength;

  // ---------------------------------------------------------------------------
  // IAppleAuthProvider Implementation
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Error Simulation Helpers
  // ---------------------------------------------------------------------------

  /// Simulate user cancellation (AuthorizationErrorCode.canceled)
  void simulateCancellation() {
    errorToThrow = const SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.canceled,
      message: 'User cancelled',
    );
  }

  /// Simulate authorization failure (AuthorizationErrorCode.failed)
  void simulateAuthorizationFailure([String message = 'Authorization failed']) {
    errorToThrow = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.failed,
      message: message,
    );
  }

  /// Simulate not handled error (AuthorizationErrorCode.notHandled)
  void simulateNotHandled([String message = 'Not handled']) {
    errorToThrow = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.notHandled,
      message: message,
    );
  }

  /// Simulate invalid response (AuthorizationErrorCode.invalidResponse)
  void simulateInvalidResponse([String message = 'Invalid response']) {
    errorToThrow = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.invalidResponse,
      message: message,
    );
  }

  /// Simulate unknown error (AuthorizationErrorCode.unknown)
  void simulateUnknownError([String message = 'Unknown error']) {
    errorToThrow = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.unknown,
      message: message,
    );
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Reset all state to defaults
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
}

// =============================================================================
// Test Data Factories
// =============================================================================

/// Helper to create a fake Apple credential for testing
///
/// Designed for sign_in_with_apple 7.x (tested with v7.0.1).
///
/// ## Field Notes (Apple Privacy Model)
/// - [userIdentifier]: Always provided, stable across sign-ins
/// - [givenName], [familyName], [email]: Only provided on FIRST sign-in,
///   null on subsequent sign-ins (Apple privacy feature)
/// - [authorizationCode]: Required, used for server-side token exchange
/// - [identityToken]: JWT containing user info, required for Supabase auth
///
/// ## Failure Simulation
/// Use [withNullIdentityToken] = true to simulate missing identity token error
///
/// ## Example
/// ```dart
/// // Subsequent sign-in (no name/email):
/// final cred = createFakeAppleCredential();
///
/// // First sign-in (includes name/email):
/// final firstCred = createFakeAppleCredentialFirstSignIn();
///
/// // Missing identity token (error case):
/// final badCred = createFakeAppleCredential(withNullIdentityToken: true);
/// ```
@visibleForTesting
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
///
/// Apple only provides name and email on the FIRST sign-in. Subsequent
/// sign-ins return null for these fields. Use this factory to test
/// first sign-in scenarios.
@visibleForTesting
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
