import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;

import 'package:prosepal/core/interfaces/google_auth_provider.dart';

/// Mock implementation of IGoogleAuthProvider for testing (google_sign_in 7.x)
///
/// ## Usage
/// ```dart
/// final mockGoogle = MockGoogleAuthProvider();
/// mockGoogle.authenticateResult = createFakeGoogleAuthResult();
/// final authService = AuthService(googleAuth: mockGoogle, ...);
///
/// await authService.signInWithGoogle();
/// expect(mockGoogle.authenticateCalls, 1);
/// expect(mockGoogle.lastScopes, ['email', 'profile']);
/// ```
///
/// ## Error Simulation
/// Use [simulateError] for package-specific exceptions:
/// ```dart
/// mockGoogle.simulateError(GoogleSignInExceptionCode.canceled);
/// mockGoogle.simulateError(GoogleSignInExceptionCode.networkError);
/// ```
///
/// ## v7.x Behavior Notes
/// - [initialize] should be called exactly once before auth methods
/// - Access tokens are obtained via separate authorization after sign-in
/// - [authenticate] returns null on cancellation (not exception)
/// - Use [simulateCancellation] = true for cancellation testing
class MockGoogleAuthProvider implements IGoogleAuthProvider {
  /// Result to return from attemptLightweightAuthentication()
  /// Set to null to simulate no previous session
  GoogleAuthResult? lightweightResult;

  /// Result to return from authenticate()
  /// Set to null to simulate user cancellation
  GoogleAuthResult? authenticateResult;

  /// Whether to simulate user cancellation (returns null from authenticate)
  bool simulateCancellation = false;

  /// Value to return from isAvailable()
  /// Set to false to simulate unsupported platform (e.g., web)
  bool isAvailableResult = true;

  /// Error to throw from authenticate() (if set)
  ///
  /// Use [simulateError] method for GoogleSignInException with specific codes
  Exception? errorToThrow;

  /// Whether to enforce single initialization (throws on multiple calls)
  bool enforcesSingleInitialization = false;

  /// Track calls for verification
  int initializeCalls = 0;
  int isAvailableCalls = 0;
  int lightweightCalls = 0;
  int authenticateCalls = 0;
  int signOutCalls = 0;
  int disconnectCalls = 0;

  String? lastServerClientId;
  String? lastClientId;
  List<String>? lastScopes;

  @override
  Future<void> initialize({
    required String? serverClientId,
    required String? clientId,
    List<String> scopes = const ['email', 'profile'],
  }) async {
    if (enforcesSingleInitialization && initializeCalls > 0) {
      throw StateError(
        'MockGoogleAuthProvider: initialize() called multiple times. '
        'The real GoogleSignIn.initialize() should only be called once.',
      );
    }
    initializeCalls++;
    lastServerClientId = serverClientId;
    lastClientId = clientId;
    lastScopes = scopes;
  }

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls++;
    return isAvailableResult;
  }

  @override
  Future<GoogleAuthResult?> attemptLightweightAuthentication() async {
    lightweightCalls++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return lightweightResult;
  }

  @override
  Future<GoogleAuthResult?> authenticate() async {
    authenticateCalls++;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    if (simulateCancellation) {
      return null;
    }

    return authenticateResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  /// Result to return from requestAdditionalScopes()
  GoogleAuthResult? additionalScopesResult;

  /// Track requestAdditionalScopes calls
  int requestAdditionalScopesCalls = 0;
  List<String>? lastAdditionalScopes;

  @override
  Future<GoogleAuthResult?> requestAdditionalScopes(List<String> scopes) async {
    requestAdditionalScopesCalls++;
    lastAdditionalScopes = scopes;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    // If no specific result set, return the authenticate result with updated scopes
    return additionalScopesResult ?? authenticateResult;
  }

  /// Simulate a GoogleSignInException with specific error code
  ///
  /// Available codes (google_sign_in_platform_interface 3.x):
  /// - [GoogleSignInExceptionCode.canceled]: User cancelled (prefer simulateCancellation)
  /// - [GoogleSignInExceptionCode.interrupted]: Operation interrupted
  /// - [GoogleSignInExceptionCode.clientConfigurationError]: Client misconfigured
  /// - [GoogleSignInExceptionCode.providerConfigurationError]: SDK unavailable
  /// - [GoogleSignInExceptionCode.uiUnavailable]: Cannot show UI
  /// - [GoogleSignInExceptionCode.userMismatch]: Wrong user on single-user platform
  /// - [GoogleSignInExceptionCode.unknownError]: Catch-all for other errors
  void simulateError(GoogleSignInExceptionCode code, [String? message]) {
    errorToThrow = GoogleSignInException(
      code: code,
      description: message ?? 'Mock error: ${code.name}',
    );
  }

  /// Simulate an interrupted operation (e.g., network issue, timeout)
  void simulateInterrupted([String message = 'Operation interrupted']) {
    simulateError(GoogleSignInExceptionCode.interrupted, message);
  }

  /// Simulate configuration error
  void simulateConfigurationError([String message = 'Client misconfigured']) {
    simulateError(GoogleSignInExceptionCode.clientConfigurationError, message);
  }

  /// Reset all state
  void reset() {
    lightweightResult = null;
    authenticateResult = null;
    additionalScopesResult = null;
    simulateCancellation = false;
    isAvailableResult = true;
    errorToThrow = null;
    enforcesSingleInitialization = false;
    initializeCalls = 0;
    isAvailableCalls = 0;
    lightweightCalls = 0;
    authenticateCalls = 0;
    signOutCalls = 0;
    disconnectCalls = 0;
    requestAdditionalScopesCalls = 0;
    lastServerClientId = null;
    lastClientId = null;
    lastScopes = null;
    lastAdditionalScopes = null;
  }
}

/// Helper to create a fake Google auth result for testing
///
/// ## v7.x Token Notes
/// - [idToken]: JWT from Google, used for Supabase signInWithIdToken
/// - [accessToken]: Obtained via separate authorizationClient call after sign-in,
///   needed for accessing Google APIs. Set to null to test missing token scenarios.
///
/// ## Failure Simulation
/// ```dart
/// // Missing ID token (Supabase auth will fail)
/// createFakeGoogleAuthResult(idToken: null);
///
/// // Missing access token (may affect some flows)
/// createFakeGoogleAuthResult(accessToken: null);
/// ```
GoogleAuthResult createFakeGoogleAuthResult({
  String? idToken = 'google-id-token-xyz',
  String? accessToken = 'google-access-token-abc',
  String? email = 'user@gmail.com',
  String? displayName = 'Test User',
}) => GoogleAuthResult(
  idToken: idToken,
  accessToken: accessToken,
  email: email,
  displayName: displayName,
);

/// Create a result with only ID token (no access token)
/// Simulates scenario where authorization was not granted
GoogleAuthResult createFakeGoogleAuthResultIdTokenOnly({
  String idToken = 'google-id-token-xyz',
  String? email = 'user@gmail.com',
  String? displayName = 'Test User',
}) =>
    GoogleAuthResult(idToken: idToken, email: email, displayName: displayName);
