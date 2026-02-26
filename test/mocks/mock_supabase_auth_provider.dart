import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prosepal/core/interfaces/supabase_auth_provider.dart';

/// Mock implementation of ISupabaseAuthProvider for testing
///
/// Designed for supabase_flutter 2.x (tested with v2.12.0).
///
/// ## Features
/// - Configurable state (user, session)
/// - Per-method error simulation via [methodErrors]
/// - Supabase-specific error helpers (rate limit, invalid credentials, etc.)
/// - Automatic auth state emission via [emitStateOnSuccess]
/// - Comprehensive call tracking with parameter capture
/// - Full MFA support (enroll, challenge, verify, unenroll)
/// - Configurable network delay simulation
///
/// ## Basic Usage
/// ```dart
/// final mockSupabase = MockSupabaseAuthProvider();
/// mockSupabase.setLoggedIn(true, email: 'user@test.com');
/// final authService = AuthService(supabaseAuth: mockSupabase, ...);
///
/// await authService.signOut();
/// expect(mockSupabase.signOutCalls, 1);
/// expect(mockSupabase.currentUser, isNull);
/// ```
///
/// ## Error Simulation
/// ```dart
/// // Using convenience methods:
/// mockSupabase.simulateInvalidCredentials();
/// mockSupabase.simulateRateLimit();
///
/// // Or per-method errors:
/// mockSupabase.methodErrors['signUp'] =
///     AuthException('User already registered', statusCode: '422');
/// ```
///
/// ## v2.x Behavior Notes
/// - [signInWithOAuth] launches browser, completion via deep link + state listener
/// - [signUp] may return null session if email confirmation required
/// - [refreshSession] throws if no current session exists
/// - Use [emitAuthState] to test listener reactions
class MockSupabaseAuthProvider implements ISupabaseAuthProvider {
  // ---------------------------------------------------------------------------
  // State Management
  // ---------------------------------------------------------------------------

  User? _currentUser;
  Session? _currentSession;

  final _authStateController = StreamController<AuthState>.broadcast();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Per-method errors (key: method name, value: exception to throw)
  ///
  /// Keys: 'signInWithIdToken', 'signInWithOAuth', 'signInWithPassword',
  /// 'signUp', 'resetPasswordForEmail', 'signInWithOtp', 'refreshSession',
  /// 'setSession', 'updateUser', 'signOut', 'deleteUser', 'mfaEnroll',
  /// 'mfaChallenge', 'mfaVerify', 'mfaUnenroll', 'mfaListFactors',
  /// 'mfaGetAuthenticatorAssuranceLevel'
  @visibleForTesting
  final Map<String, Exception> methodErrors = {};

  /// Whether to emit auth state changes on successful auth operations
  @visibleForTesting
  bool emitStateOnSuccess = false;

  /// Simulated network delay for async operations
  /// Useful for testing loading indicators and timeouts
  @visibleForTesting
  Duration? simulateDelay;

  Future<void> _maybeDelay() async {
    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }
  }

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times signInWithIdToken() was called
  @visibleForTesting
  int signInWithIdTokenCalls = 0;

  /// Number of times signInWithOAuth() was called
  @visibleForTesting
  int signInWithOAuthCalls = 0;

  /// Number of times signInWithPassword() was called
  @visibleForTesting
  int signInWithPasswordCalls = 0;

  /// Number of times signUp() was called
  @visibleForTesting
  int signUpCalls = 0;

  /// Number of times resetPasswordForEmail() was called
  @visibleForTesting
  int resetPasswordCalls = 0;

  /// Number of times signInWithOtp() was called
  @visibleForTesting
  int signInWithOtpCalls = 0;

  /// Number of times refreshSession() was called
  @visibleForTesting
  int refreshSessionCalls = 0;

  /// Number of times setSession() was called
  @visibleForTesting
  int setSessionCalls = 0;

  /// Number of times updateUser() was called
  @visibleForTesting
  int updateUserCalls = 0;

  /// Number of times signOut() was called
  @visibleForTesting
  int signOutCalls = 0;

  /// Number of times deleteUser() was called
  @visibleForTesting
  int deleteUserCalls = 0;

  // ---------------------------------------------------------------------------
  // Parameter Tracking
  // ---------------------------------------------------------------------------

  /// Last OAuth provider used
  @visibleForTesting
  OAuthProvider? lastProvider;

  /// Last ID token passed to signInWithIdToken()
  @visibleForTesting
  String? lastIdToken;

  /// Last nonce passed to signInWithIdToken()
  @visibleForTesting
  String? lastNonce;

  /// Last access token passed
  @visibleForTesting
  String? lastAccessToken;

  /// Last email used in any email method
  @visibleForTesting
  String? lastEmail;

  /// Last password used
  @visibleForTesting
  String? lastPassword;

  /// Last redirect URL used
  @visibleForTesting
  String? lastRedirectTo;

  /// Last OAuth scopes requested
  @visibleForTesting
  String? lastScopes;

  /// Last captcha token passed
  @visibleForTesting
  String? lastCaptchaToken;

  /// Last data payload passed to signUp()
  @visibleForTesting
  Map<String, dynamic>? lastData;

  /// Last query params passed to signInWithOAuth()
  @visibleForTesting
  Map<String, String>? lastQueryParams;

  /// Last user attributes passed to updateUser()
  @visibleForTesting
  UserAttributes? lastUserAttributes;

  /// Last refresh token passed to setSession()
  @visibleForTesting
  String? lastRefreshToken;

  // ---------------------------------------------------------------------------
  // Error Simulation Helpers
  // ---------------------------------------------------------------------------

  Exception? _getError(String method) => methodErrors[method];

  /// Simulate invalid login credentials (400)
  void simulateInvalidCredentials([
    String message = 'Invalid login credentials',
  ]) {
    methodErrors['signInWithPassword'] = AuthException(
      message,
      statusCode: '400',
    );
  }

  /// Simulate user already registered (422)
  void simulateUserAlreadyRegistered([
    String message = 'User already registered',
  ]) {
    methodErrors['signUp'] = AuthException(message, statusCode: '422');
  }

  /// Simulate email not confirmed (400)
  void simulateEmailNotConfirmed([String message = 'Email not confirmed']) {
    methodErrors['signInWithPassword'] = AuthException(
      message,
      statusCode: '400',
    );
  }

  /// Simulate rate limiting (429)
  void simulateRateLimit([
    String message = 'For security purposes, you can only request this after 60 seconds',
  ]) {
    methodErrors['signInWithPassword'] = AuthException(
      message,
      statusCode: '429',
    );
    methodErrors['signUp'] = AuthException(message, statusCode: '429');
    methodErrors['resetPasswordForEmail'] = AuthException(
      message,
      statusCode: '429',
    );
    methodErrors['signInWithOtp'] = AuthException(message, statusCode: '429');
  }

  /// Simulate session expired (401)
  void simulateSessionExpired([
    String message = 'Token has expired or is invalid',
  ]) {
    methodErrors['refreshSession'] = AuthException(message, statusCode: '401');
  }

  /// Simulate weak password (422)
  void simulateWeakPassword([
    String message = 'Password should be at least 6 characters',
  ]) {
    methodErrors['signUp'] = AuthException(message, statusCode: '422');
    methodErrors['updateUser'] = AuthException(message, statusCode: '422');
  }

  /// Simulate network error
  void simulateNetworkError([String message = 'Network error']) {
    final error = AuthException(message, statusCode: '0');
    methodErrors['signInWithPassword'] = error;
    methodErrors['signUp'] = error;
    methodErrors['refreshSession'] = error;
  }

  /// Clear all error simulations
  void clearErrors() {
    methodErrors.clear();
  }

  // ---------------------------------------------------------------------------
  // ISupabaseAuthProvider Implementation
  // ---------------------------------------------------------------------------

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  /// Set logged in state with fake user/session
  void setLoggedIn(
    bool value, {
    String email = 'test@example.com',
    String? displayName,
  }) {
    if (value) {
      _currentUser = createFakeUser(email: email, displayName: displayName);
      _currentSession = createFakeSession(user: _currentUser);
    } else {
      _currentUser = null;
      _currentSession = null;
    }
  }

  /// Emit an auth state event for testing listener reactions
  void emitAuthState(AuthState state) {
    _authStateController.add(state);
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) async {
    signInWithIdTokenCalls++;
    lastProvider = provider;
    lastIdToken = idToken;
    lastNonce = nonce;
    lastAccessToken = accessToken;
    await _maybeDelay();

    final error = _getError('signInWithIdToken');
    if (error != null) throw error;

    final user = createFakeUser(email: 'oauth@example.com');
    _currentUser = user;
    _currentSession = createFakeSession(user: user);

    if (emitStateOnSuccess) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, _currentSession));
    }

    return AuthResponse(session: _currentSession, user: user);
  }

  @override
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) async {
    signInWithOAuthCalls++;
    lastProvider = provider;
    lastRedirectTo = redirectTo;
    lastScopes = scopes;
    lastQueryParams = queryParams;
    await _maybeDelay();

    final error = _getError('signInWithOAuth');
    if (error != null) throw error;

    return true; // Browser launched successfully
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    signInWithPasswordCalls++;
    lastEmail = email;
    lastPassword = password;
    lastCaptchaToken = captchaToken;
    await _maybeDelay();

    final error = _getError('signInWithPassword');
    if (error != null) throw error;

    final user = createFakeUser(email: email);
    _currentUser = user;
    _currentSession = createFakeSession(user: user);

    if (emitStateOnSuccess) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, _currentSession));
    }

    return AuthResponse(session: _currentSession, user: user);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? captchaToken,
  }) async {
    signUpCalls++;
    lastEmail = email;
    lastPassword = password;
    lastData = data;
    lastCaptchaToken = captchaToken;
    await _maybeDelay();

    final error = _getError('signUp');
    if (error != null) throw error;

    final user = createFakeUser(email: email, emailConfirmed: false);
    _currentUser = user;
    // No session until email confirmed
    return AuthResponse(user: user);
  }

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    resetPasswordCalls++;
    lastEmail = email;
    lastRedirectTo = redirectTo;
    lastCaptchaToken = captchaToken;
    await _maybeDelay();

    final error = _getError('resetPasswordForEmail');
    if (error != null) throw error;
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    String? emailRedirectTo,
    String? captchaToken,
  }) async {
    signInWithOtpCalls++;
    lastEmail = email;
    lastRedirectTo = emailRedirectTo;
    lastCaptchaToken = captchaToken;
    await _maybeDelay();

    final error = _getError('signInWithOtp');
    if (error != null) throw error;
  }

  @override
  Future<AuthResponse> refreshSession() async {
    refreshSessionCalls++;
    await _maybeDelay();

    final error = _getError('refreshSession');
    if (error != null) throw error;

    if (_currentSession == null) {
      throw const AuthException('No session to refresh');
    }

    // Return current session (simulating refresh)
    return AuthResponse(session: _currentSession, user: _currentUser);
  }

  @override
  Future<AuthResponse> setSession(String refreshToken) async {
    setSessionCalls++;
    lastRefreshToken = refreshToken;
    await _maybeDelay();

    final error = _getError('setSession');
    if (error != null) throw error;

    final user = createFakeUser();
    _currentUser = user;
    _currentSession = createFakeSession(user: user, refreshToken: refreshToken);

    return AuthResponse(session: _currentSession, user: user);
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes) async {
    updateUserCalls++;
    lastUserAttributes = attributes;
    await _maybeDelay();

    final error = _getError('updateUser');
    if (error != null) throw error;

    // Update email if provided
    if (attributes.email != null && _currentUser != null) {
      _currentUser = createFakeUser(email: attributes.email!);
    }

    // UserResponse is created from JSON in real SDK
    // We create a minimal valid response
    return UserResponse.fromJson({
      'user': {
        'id': _currentUser?.id ?? 'test-id',
        'email': _currentUser?.email ?? 'test@example.com',
        'aud': 'authenticated',
        'app_metadata': {},
        'user_metadata': {},
        'created_at': DateTime.now().toIso8601String(),
      },
    });
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await _maybeDelay();

    final error = _getError('signOut');
    if (error != null) throw error;

    _currentUser = null;
    _currentSession = null;

    if (emitStateOnSuccess) {
      emitAuthState(const AuthState(AuthChangeEvent.signedOut, null));
    }
  }

  @override
  Future<void> deleteUser() async {
    deleteUserCalls++;
    await _maybeDelay();

    final error = _getError('deleteUser');
    if (error != null) throw error;

    _currentUser = null;
    _currentSession = null;
  }

  @override
  Future<void> exchangeAppleToken(
    String authorizationCode, {
    String? accessToken,
  }) async {
    // No-op in mock - just track if needed
  }

  @override
  Future<Map<String, bool>> verifyEdgeFunctions() async {
    // Mock always returns success
    return {
      'delete-user': true,
      'exchange-apple-token': true,
    };
  }

  // ---------------------------------------------------------------------------
  // MFA Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times mfaEnroll() was called
  @visibleForTesting
  int mfaEnrollCalls = 0;

  /// Number of times mfaChallenge() was called
  @visibleForTesting
  int mfaChallengeCalls = 0;

  /// Number of times mfaVerify() was called
  @visibleForTesting
  int mfaVerifyCalls = 0;

  /// Number of times mfaUnenroll() was called
  @visibleForTesting
  int mfaUnenrollCalls = 0;

  /// Number of times mfaListFactors() was called
  @visibleForTesting
  int mfaListFactorsCalls = 0;

  /// Number of times mfaGetAuthenticatorAssuranceLevel() was called
  @visibleForTesting
  int mfaGetAALCalls = 0;

  /// Last factor ID passed to MFA methods
  @visibleForTesting
  String? lastMfaFactorId;

  /// Last challenge ID passed to mfaVerify()
  @visibleForTesting
  String? lastMfaChallengeId;

  /// Last TOTP code passed to mfaVerify()
  @visibleForTesting
  String? lastMfaCode;

  /// Last friendly name passed to mfaEnroll()
  @visibleForTesting
  String? lastMfaFriendlyName;

  // ---------------------------------------------------------------------------
  // MFA Configuration
  // ---------------------------------------------------------------------------

  /// Mock MFA factors for testing
  @visibleForTesting
  List<Factor> mockFactors = [];

  /// Mock current AAL level ('aal1' or 'aal2')
  @visibleForTesting
  AuthenticatorAssuranceLevels mockCurrentAAL = AuthenticatorAssuranceLevels.aal1;

  /// Mock next AAL level ('aal1' or 'aal2')
  @visibleForTesting
  AuthenticatorAssuranceLevels mockNextAAL = AuthenticatorAssuranceLevels.aal1;

  // ---------------------------------------------------------------------------
  // MFA Implementation
  // ---------------------------------------------------------------------------

  @override
  Future<AuthMFAEnrollResponse> mfaEnroll({String? friendlyName}) async {
    mfaEnrollCalls++;
    lastMfaFriendlyName = friendlyName;
    await _maybeDelay();

    final error = _getError('mfaEnroll');
    if (error != null) throw error;

    // Return mock enrollment response
    return AuthMFAEnrollResponse.fromJson({
      'id': 'mock-factor-id',
      'type': 'totp',
      'totp': {
        'qr_code': 'data:image/svg+xml;base64,mock-qr-code',
        'secret': 'MOCK_SECRET_BASE32',
        'uri': 'otpauth://totp/App:user@example.com?secret=MOCK_SECRET_BASE32',
      },
    });
  }

  @override
  Future<AuthMFAChallengeResponse> mfaChallenge(String factorId) async {
    mfaChallengeCalls++;
    lastMfaFactorId = factorId;
    await _maybeDelay();

    final error = _getError('mfaChallenge');
    if (error != null) throw error;

    return AuthMFAChallengeResponse.fromJson({
      'id': 'mock-challenge-id',
      'expires_at': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
    });
  }

  @override
  Future<AuthMFAVerifyResponse> mfaVerify({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    mfaVerifyCalls++;
    lastMfaFactorId = factorId;
    lastMfaChallengeId = challengeId;
    lastMfaCode = code;
    await _maybeDelay();

    final error = _getError('mfaVerify');
    if (error != null) throw error;

    // Simulate session upgrade to aal2
    final user = _currentUser ?? createFakeUser();
    _currentSession = createFakeSession(user: user);

    return AuthMFAVerifyResponse.fromJson({
      'access_token': 'mock-aal2-access-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'mock-aal2-refresh-token',
      'user': {
        'id': user.id,
        'email': user.email,
        'aud': 'authenticated',
        'role': 'authenticated',
        'created_at': DateTime.now().toIso8601String(),
      },
    });
  }

  @override
  Future<AuthMFAUnenrollResponse> mfaUnenroll(String factorId) async {
    mfaUnenrollCalls++;
    lastMfaFactorId = factorId;
    await _maybeDelay();

    final error = _getError('mfaUnenroll');
    if (error != null) throw error;

    // Remove from mock factors
    mockFactors.removeWhere((f) => f.id == factorId);

    return AuthMFAUnenrollResponse.fromJson({'id': factorId});
  }

  @override
  Future<AuthMFAListFactorsResponse> mfaListFactors() async {
    mfaListFactorsCalls++;
    await _maybeDelay();

    final error = _getError('mfaListFactors');
    if (error != null) throw error;

    return AuthMFAListFactorsResponse(
      all: mockFactors,
      totp: mockFactors.where((f) => f.factorType == FactorType.totp).toList(),
      phone: mockFactors.where((f) => f.factorType == FactorType.phone).toList(),
    );
  }

  @override
  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse>
      mfaGetAuthenticatorAssuranceLevel() async {
    mfaGetAALCalls++;
    await _maybeDelay();

    final error = _getError('mfaGetAuthenticatorAssuranceLevel');
    if (error != null) throw error;

    return AuthMFAGetAuthenticatorAssuranceLevelResponse(
      currentLevel: mockCurrentAAL,
      nextLevel: mockNextAAL,
      currentAuthenticationMethods: [],
    );
  }

  // ---------------------------------------------------------------------------
  // Reset & Dispose
  // ---------------------------------------------------------------------------

  /// Reset all state and counters to defaults
  void reset() {
    _currentUser = null;
    _currentSession = null;
    emitStateOnSuccess = false;
    simulateDelay = null;
    methodErrors.clear();
    signInWithIdTokenCalls = 0;
    signInWithOAuthCalls = 0;
    signInWithPasswordCalls = 0;
    signUpCalls = 0;
    resetPasswordCalls = 0;
    signInWithOtpCalls = 0;
    refreshSessionCalls = 0;
    setSessionCalls = 0;
    updateUserCalls = 0;
    signOutCalls = 0;
    deleteUserCalls = 0;
    lastProvider = null;
    lastIdToken = null;
    lastNonce = null;
    lastAccessToken = null;
    lastEmail = null;
    lastPassword = null;
    lastRedirectTo = null;
    lastScopes = null;
    lastCaptchaToken = null;
    lastData = null;
    lastQueryParams = null;
    lastUserAttributes = null;
    lastRefreshToken = null;
    // MFA
    mfaEnrollCalls = 0;
    mfaChallengeCalls = 0;
    mfaVerifyCalls = 0;
    mfaUnenrollCalls = 0;
    mfaListFactorsCalls = 0;
    mfaGetAALCalls = 0;
    lastMfaFactorId = null;
    lastMfaChallengeId = null;
    lastMfaCode = null;
    lastMfaFriendlyName = null;
    mockFactors = [];
    mockCurrentAAL = AuthenticatorAssuranceLevels.aal1;
    mockNextAAL = AuthenticatorAssuranceLevels.aal1;
  }

  /// Dispose the stream controller to prevent leaks
  void dispose() {
    _authStateController.close();
  }
}

// =============================================================================
// Test Data Factories
// =============================================================================

/// Creates a fake User for testing
///
/// Designed for supabase_flutter 2.x (tested with v2.12.0).
///
/// ## Example
/// ```dart
/// // Basic user:
/// final user = createFakeUser(email: 'test@example.com');
///
/// // Unconfirmed email (sign-up scenario):
/// final unconfirmed = createFakeUser(emailConfirmed: false);
///
/// // User with display name:
/// final named = createFakeUser(displayName: 'John Doe');
/// ```
@visibleForTesting
User createFakeUser({
  String id = 'test-user-id-123',
  String email = 'test@example.com',
  String? displayName,
  bool emailConfirmed = true,
  Map<String, dynamic>? userMetadata,
}) {
  final now = DateTime.now().toIso8601String();
  return User(
    id: id,
    email: email,
    aud: 'authenticated',
    appMetadata: {
      'provider': 'email',
      'providers': ['email'],
    },
    userMetadata:
        userMetadata ??
        {
          if (displayName != null) 'full_name': displayName,
          if (displayName != null) 'name': displayName,
        },
    createdAt: now,
    emailConfirmedAt: emailConfirmed ? now : null,
    role: 'authenticated',
    updatedAt: now,
  );
}

/// Creates a fake Session for testing
///
/// ## Example
/// ```dart
/// final session = createFakeSession(
///   user: createFakeUser(email: 'test@example.com'),
///   expiresIn: 7200,
/// );
/// ```
@visibleForTesting
Session createFakeSession({
  String accessToken = 'fake-access-token-xyz',
  String refreshToken = 'fake-refresh-token-abc',
  int expiresIn = 3600,
  User? user,
}) {
  return Session(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: expiresIn,
    tokenType: 'bearer',
    user: user ?? createFakeUser(),
  );
}
