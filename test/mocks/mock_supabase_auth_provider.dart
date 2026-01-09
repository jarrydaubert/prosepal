import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prosepal/core/interfaces/supabase_auth_provider.dart';

/// Mock implementation of ISupabaseAuthProvider for testing (supabase_flutter 2.x)
///
/// ## Usage
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
/// Use [methodErrors] for per-method AuthException injection:
/// ```dart
/// mockSupabase.methodErrors['signInWithPassword'] =
///     AuthException('Invalid login credentials');
/// mockSupabase.methodErrors['signUp'] =
///     AuthException('User already registered');
/// ```
///
/// ## v2.x Behavior Notes
/// - [signInWithOAuth] launches browser, completion via deep link + state listener
/// - [signUp] may return null session if email confirmation required
/// - [refreshSession] throws if no current session exists
/// - Use [emitAuthState] to test listener reactions
class MockSupabaseAuthProvider implements ISupabaseAuthProvider {
  User? _currentUser;
  Session? _currentSession;

  final _authStateController = StreamController<AuthState>.broadcast();

  /// Per-method errors (key: method name, value: exception to throw)
  ///
  /// Common AuthException messages:
  /// - 'Invalid login credentials' (wrong email/password)
  /// - 'User already registered' (signup with existing email)
  /// - 'Email not confirmed' (login before verification)
  /// - 'Token has expired or is invalid' (expired session)
  /// - 'For security purposes, you can only request this after X seconds'
  final Map<String, Exception> methodErrors = {};

  /// Whether to emit auth state changes on successful auth operations
  bool emitStateOnSuccess = false;

  /// Track calls for verification
  int signInWithIdTokenCalls = 0;
  int signInWithOAuthCalls = 0;
  int signInWithPasswordCalls = 0;
  int signUpCalls = 0;
  int resetPasswordCalls = 0;
  int signInWithOtpCalls = 0;
  int refreshSessionCalls = 0;
  int setSessionCalls = 0;
  int updateUserCalls = 0;
  int signOutCalls = 0;
  int deleteUserCalls = 0;

  /// Last parameters passed
  OAuthProvider? lastProvider;
  String? lastIdToken;
  String? lastNonce;
  String? lastAccessToken;
  String? lastEmail;
  String? lastPassword;
  String? lastRedirectTo;
  String? lastScopes;
  String? lastCaptchaToken;
  Map<String, dynamic>? lastData;
  Map<String, String>? lastQueryParams;
  UserAttributes? lastUserAttributes;
  String? lastRefreshToken;

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

  /// Emit an auth state event
  void emitAuthState(AuthState state) {
    _authStateController.add(state);
  }

  Exception? _getError(String method) => methodErrors[method];

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

    final error = _getError('signInWithOtp');
    if (error != null) throw error;
  }

  @override
  Future<AuthResponse> refreshSession() async {
    refreshSessionCalls++;

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

  // ===========================================================================
  // MFA Methods (mock implementations)
  // ===========================================================================

  int mfaEnrollCalls = 0;
  int mfaChallengeCalls = 0;
  int mfaVerifyCalls = 0;
  int mfaUnenrollCalls = 0;
  int mfaListFactorsCalls = 0;
  int mfaGetAALCalls = 0;

  String? lastMfaFactorId;
  String? lastMfaChallengeId;
  String? lastMfaCode;
  String? lastMfaFriendlyName;

  /// Mock MFA factors for testing
  List<Factor> mockFactors = [];

  /// Mock AAL level ('aal1' or 'aal2')
  AuthenticatorAssuranceLevels mockCurrentAAL = AuthenticatorAssuranceLevels.aal1;
  AuthenticatorAssuranceLevels mockNextAAL = AuthenticatorAssuranceLevels.aal1;

  @override
  Future<AuthMFAEnrollResponse> mfaEnroll({String? friendlyName}) async {
    mfaEnrollCalls++;
    lastMfaFriendlyName = friendlyName;

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

    final error = _getError('mfaUnenroll');
    if (error != null) throw error;

    // Remove from mock factors
    mockFactors.removeWhere((f) => f.id == factorId);

    return AuthMFAUnenrollResponse.fromJson({'id': factorId});
  }

  @override
  Future<AuthMFAListFactorsResponse> mfaListFactors() async {
    mfaListFactorsCalls++;

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

    final error = _getError('mfaGetAuthenticatorAssuranceLevel');
    if (error != null) throw error;

    return AuthMFAGetAuthenticatorAssuranceLevelResponse(
      currentLevel: mockCurrentAAL,
      nextLevel: mockNextAAL,
      currentAuthenticationMethods: [],
    );
  }

  /// Reset all state
  void reset() {
    _currentUser = null;
    _currentSession = null;
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

  void dispose() {
    _authStateController.close();
  }
}

/// Creates a fake User for testing
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
