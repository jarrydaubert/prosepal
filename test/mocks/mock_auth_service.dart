import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:prosepal/core/interfaces/auth_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// Test Data Factories
// =============================================================================

/// Creates a fake User for testing
///
/// Designed for supabase_flutter 2.x (tested with v2.12.0).
/// All fields are configurable with sensible defaults.
///
/// ## Example
/// ```dart
/// // Basic user:
/// final user = createFakeUser(email: 'test@example.com');
///
/// // Unconfirmed email (sign-up scenario):
/// final unconfirmed = createFakeUser(emailConfirmed: false);
///
/// // Anonymous user:
/// final anon = createFakeUser(isAnonymous: true);
/// ```
@visibleForTesting
User createFakeUser({
  String id = 'test-user-id-123',
  String email = 'test@example.com',
  String? displayName,
  String? phone,
  bool emailConfirmed = true,
  bool isAnonymous = false,
  DateTime? createdAt,
  DateTime? lastSignInAt,
  Map<String, dynamic>? userMetadata,
}) {
  final now = DateTime.now().toIso8601String();
  return User(
    id: id,
    email: email,
    phone: phone,
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
    createdAt: createdAt?.toIso8601String() ?? now,
    lastSignInAt: lastSignInAt?.toIso8601String() ?? now,
    emailConfirmedAt: emailConfirmed ? now : null,
    role: 'authenticated',
    updatedAt: now,
    isAnonymous: isAnonymous,
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

/// Mock implementation of IAuthService for testing
///
/// Designed for supabase_flutter 2.x (tested with v2.12.0).
///
/// ## Features
/// - Configurable state via [setLoggedIn], [setUser]
/// - Auto-emits auth state events when [autoEmitAuthState] is true
/// - Per-method error simulation via [methodErrors]
/// - Supabase-specific error helpers (rate limit, invalid credentials, etc.)
/// - Simulated network delay via [simulateDelay]
/// - Call tracking for verification
/// - Rich fake User/Session objects
///
/// ## Basic Usage
/// ```dart
/// final mockAuth = MockAuthService();
/// mockAuth.setLoggedIn(true, email: 'user@test.com');
/// mockAuth.autoEmitAuthState = true;
/// ```
///
/// ## Error Simulation
/// ```dart
/// // Rate limit error:
/// mockAuth.simulateRateLimit();
///
/// // Invalid credentials:
/// mockAuth.simulateInvalidCredentials();
///
/// // Per-method error:
/// mockAuth.methodErrors['signInWithEmail'] = AuthException('Bad request');
/// ```
class MockAuthService implements IAuthService {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// If true, automatically emits AuthState events on sign-in/sign-out
  @visibleForTesting
  bool autoEmitAuthState = false;

  /// Simulated network delay for async operations
  /// Useful for testing loading indicators
  @visibleForTesting
  Duration? simulateDelay;

  // ---------------------------------------------------------------------------
  // State Management
  // ---------------------------------------------------------------------------

  User? _currentUser;
  bool _isLoggedIn = false;
  String? _displayName;
  String? _email;

  final _authStateController = StreamController<AuthState>.broadcast();

  /// Set the logged-in state with optional email and display name
  void setLoggedIn(bool value, {String? email, String? displayName}) {
    _isLoggedIn = value;
    _email = email;
    _displayName = displayName;
  }

  /// Set a specific User object
  void setUser(User? user) {
    _currentUser = user;
    _isLoggedIn = user != null;
  }

  /// Manually emit an auth state event for fine-grained control
  void emitAuthState(AuthState state) {
    _authStateController.add(state);
  }

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times signInWithApple() was called
  @visibleForTesting
  int signInWithAppleCallCount = 0;

  /// Number of times signInWithGoogle() was called
  @visibleForTesting
  int signInWithGoogleCallCount = 0;

  /// Number of times signInWithEmail() was called
  @visibleForTesting
  int signInWithEmailCallCount = 0;

  /// Number of times signUpWithEmail() was called
  @visibleForTesting
  int signUpWithEmailCallCount = 0;

  /// Number of times resetPassword() was called
  @visibleForTesting
  int resetPasswordCallCount = 0;

  /// Number of times signInWithMagicLink() was called
  @visibleForTesting
  int signInWithMagicLinkCallCount = 0;

  /// Number of times updateEmail() was called
  @visibleForTesting
  int updateEmailCallCount = 0;

  /// Number of times updatePassword() was called
  @visibleForTesting
  int updatePasswordCallCount = 0;

  /// Number of times signOut() was called
  @visibleForTesting
  int signOutCallCount = 0;

  /// Number of times deleteAccount() was called
  @visibleForTesting
  int deleteAccountCallCount = 0;

  /// Last email passed to any email method
  @visibleForTesting
  String? lastEmailUsed;

  /// Last password passed to any password method
  @visibleForTesting
  String? lastPasswordUsed;

  // ---------------------------------------------------------------------------
  // Error Simulation
  // ---------------------------------------------------------------------------

  /// Global error - thrown by any method if set
  @visibleForTesting
  Exception? errorToThrow;

  /// Per-method errors - takes precedence over [errorToThrow]
  ///
  /// Keys: 'signInWithEmail', 'signUpWithEmail', 'signInWithApple',
  /// 'signInWithGoogle', 'signOut', 'resetPassword', 'signInWithMagicLink',
  /// 'updateEmail', 'updatePassword', 'deleteAccount'
  @visibleForTesting
  final Map<String, Exception> methodErrors = {};

  Exception? _getError(String method) {
    return methodErrors[method] ?? errorToThrow;
  }

  /// Simulate rate limiting (429)
  void simulateRateLimit([String message = 'Rate limit exceeded']) {
    errorToThrow = AuthException(message, statusCode: '429');
  }

  /// Simulate invalid credentials (400)
  void simulateInvalidCredentials([
    String message = 'Invalid login credentials',
  ]) {
    errorToThrow = AuthException(message, statusCode: '400');
  }

  /// Simulate email not confirmed (400)
  void simulateEmailNotConfirmed([String message = 'Email not confirmed']) {
    errorToThrow = AuthException(message, statusCode: '400');
  }

  /// Simulate user not found (400)
  void simulateUserNotFound([String message = 'User not found']) {
    errorToThrow = AuthException(message, statusCode: '400');
  }

  /// Simulate email already registered (422)
  void simulateEmailAlreadyRegistered([
    String message = 'User already registered',
  ]) {
    errorToThrow = AuthException(message, statusCode: '422');
  }

  /// Simulate weak password (422)
  void simulateWeakPassword([
    String message = 'Password should be at least 6 characters',
  ]) {
    errorToThrow = AuthException(message, statusCode: '422');
  }

  /// Simulate session expired (401)
  void simulateSessionExpired([String message = 'Session expired']) {
    errorToThrow = AuthException(message, statusCode: '401');
  }

  /// Simulate network error
  void simulateNetworkError([String message = 'Network error']) {
    errorToThrow = AuthException(message, statusCode: '0');
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Reset all state and counters to defaults
  void reset() {
    _currentUser = null;
    _isLoggedIn = false;
    _displayName = null;
    _email = null;
    autoEmitAuthState = false;
    simulateDelay = null;
    signInWithAppleCallCount = 0;
    signInWithGoogleCallCount = 0;
    signInWithEmailCallCount = 0;
    signUpWithEmailCallCount = 0;
    resetPasswordCallCount = 0;
    signInWithMagicLinkCallCount = 0;
    updateEmailCallCount = 0;
    updatePasswordCallCount = 0;
    signOutCallCount = 0;
    deleteAccountCallCount = 0;
    lastEmailUsed = null;
    lastPasswordUsed = null;
    errorToThrow = null;
    methodErrors.clear();
  }

  Future<void> _maybeDelay() async {
    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }
  }

  // ---------------------------------------------------------------------------
  // IAuthService Implementation
  // ---------------------------------------------------------------------------

  @override
  Future<void> initializeProviders() async {
    // No-op in mock - providers don't need initialization
  }

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  String? get displayName => _displayName;

  @override
  String? get email => _email;

  @override
  Future<AuthResponse> signInWithApple() async {
    signInWithAppleCallCount++;
    await _maybeDelay();
    final error = _getError('signInWithApple');
    if (error != null) throw error;
    final user = createFakeUser(
      email: 'apple@privaterelay.appleid.com',
      displayName: _displayName,
    );
    _currentUser = user;
    _isLoggedIn = true;
    _email = user.email;
    final session = createFakeSession(user: user);
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, session));
    }
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    signInWithGoogleCallCount++;
    await _maybeDelay();
    final error = _getError('signInWithGoogle');
    if (error != null) throw error;
    final user = createFakeUser(
      email: _email ?? 'google@gmail.com',
      displayName: _displayName,
    );
    _currentUser = user;
    _isLoggedIn = true;
    _email = user.email;
    final session = createFakeSession(user: user);
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, session));
    }
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInWithEmailCallCount++;
    lastEmailUsed = email;
    lastPasswordUsed = password;
    await _maybeDelay();
    final error = _getError('signInWithEmail');
    if (error != null) throw error;
    final user = createFakeUser(email: email, displayName: _displayName);
    _currentUser = user;
    _isLoggedIn = true;
    _email = email;
    final session = createFakeSession(user: user);
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, session));
    }
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpWithEmailCallCount++;
    lastEmailUsed = email;
    lastPasswordUsed = password;
    final error = _getError('signUpWithEmail');
    if (error != null) throw error;
    // Sign up may not confirm email immediately
    final user = createFakeUser(email: email, emailConfirmed: false);
    _currentUser = user;
    _email = email;
    return AuthResponse(user: user);
  }

  @override
  Future<void> resetPassword(String email) async {
    resetPasswordCallCount++;
    lastEmailUsed = email;
    final error = _getError('resetPassword');
    if (error != null) throw error;
  }

  @override
  Future<void> signInWithMagicLink(String email) async {
    signInWithMagicLinkCallCount++;
    lastEmailUsed = email;
    await _maybeDelay();
    final error = _getError('signInWithMagicLink');
    if (error != null) throw error;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    updateEmailCallCount++;
    await _maybeDelay();
    final error = _getError('updateEmail');
    if (error != null) throw error;
    _email = newEmail;
    if (autoEmitAuthState) {
      emitAuthState(const AuthState(AuthChangeEvent.userUpdated, null));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    updatePasswordCallCount++;
    lastPasswordUsed = newPassword;
    await _maybeDelay();
    final error = _getError('updatePassword');
    if (error != null) throw error;
    if (autoEmitAuthState) {
      emitAuthState(const AuthState(AuthChangeEvent.userUpdated, null));
    }
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    final error = _getError('signOut');
    if (error != null) throw error;
    _isLoggedIn = false;
    _currentUser = null;
    _email = null;
    _displayName = null;
    if (autoEmitAuthState) {
      emitAuthState(const AuthState(AuthChangeEvent.signedOut, null));
    }
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCallCount++;
    final error = _getError('deleteAccount');
    if (error != null) throw error;
    await signOut();
  }

  void dispose() {
    _authStateController.close();
  }
}
