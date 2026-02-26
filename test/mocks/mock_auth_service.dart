import 'dart:async';

import 'package:prosepal/core/interfaces/auth_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Creates a fake User for testing
/// All fields are configurable with sensible defaults
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
    appMetadata: {'provider': 'email', 'providers': ['email']},
    userMetadata: userMetadata ?? {
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
/// Features:
/// - Configurable state via [setLoggedIn], [setUser]
/// - Auto-emits auth state events when [autoEmitAuthState] is true
/// - Per-method error simulation via [methodErrors]
/// - Call tracking for verification
/// - Rich fake User/Session objects
class MockAuthService implements IAuthService {
  /// If true, automatically emits AuthState events on sign-in/sign-out
  bool autoEmitAuthState = false;

  // Configurable state for tests
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

  /// Manually emit an auth state event
  void emitAuthState(AuthState state) {
    _authStateController.add(state);
  }

  // Tracking for test verification
  int signInWithAppleCallCount = 0;
  int signInWithGoogleCallCount = 0;
  int signInWithEmailCallCount = 0;
  int signUpWithEmailCallCount = 0;
  int resetPasswordCallCount = 0;
  int signOutCallCount = 0;
  int deleteAccountCallCount = 0;

  String? lastEmailUsed;
  String? lastPasswordUsed;

  /// Global error - thrown by any method if set
  Exception? errorToThrow;

  /// Per-method errors - takes precedence over [errorToThrow]
  /// Keys: 'signInWithEmail', 'signUpWithEmail', 'signInWithApple',
  /// 'signInWithGoogle', 'signOut', 'resetPassword', 'signInWithMagicLink',
  /// 'updateEmail', 'updatePassword', 'deleteAccount'
  final Map<String, Exception> methodErrors = {};

  Exception? _getError(String method) {
    return methodErrors[method] ?? errorToThrow;
  }

  /// Reset all state and counters
  void reset() {
    _currentUser = null;
    _isLoggedIn = false;
    _displayName = null;
    _email = null;
    autoEmitAuthState = false;
    signInWithAppleCallCount = 0;
    signInWithGoogleCallCount = 0;
    signInWithEmailCallCount = 0;
    signUpWithEmailCallCount = 0;
    resetPasswordCallCount = 0;
    signOutCallCount = 0;
    deleteAccountCallCount = 0;
    lastEmailUsed = null;
    lastPasswordUsed = null;
    errorToThrow = null;
    methodErrors.clear();
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
    final error = _getError('signInWithApple');
    if (error != null) throw error;
    final user = createFakeUser(
      email: 'apple@privaterelay.appleid.com',
      displayName: _displayName,
    );
    _currentUser = user;
    _isLoggedIn = true;
    _email = user.email;
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, null));
    }
    return AuthResponse(
      session: createFakeSession(user: user),
      user: user,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    signInWithGoogleCallCount++;
    final error = _getError('signInWithGoogle');
    if (error != null) throw error;
    final user = createFakeUser(
      email: _email ?? 'google@gmail.com',
      displayName: _displayName,
    );
    _currentUser = user;
    _isLoggedIn = true;
    _email = user.email;
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, null));
    }
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInWithEmailCallCount++;
    lastEmailUsed = email;
    lastPasswordUsed = password;
    final error = _getError('signInWithEmail');
    if (error != null) throw error;
    final user = createFakeUser(email: email, displayName: _displayName);
    _currentUser = user;
    _isLoggedIn = true;
    _email = email;
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.signedIn, null));
    }
    return AuthResponse(
      session: createFakeSession(user: user),
      user: user,
    );
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
    return AuthResponse(
      session: null, // No session until email confirmed
      user: user,
    );
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
    lastEmailUsed = email;
    final error = _getError('signInWithMagicLink');
    if (error != null) throw error;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final error = _getError('updateEmail');
    if (error != null) throw error;
    _email = newEmail;
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.userUpdated, null));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final error = _getError('updatePassword');
    if (error != null) throw error;
    if (autoEmitAuthState) {
      emitAuthState(AuthState(AuthChangeEvent.userUpdated, null));
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
      emitAuthState(AuthState(AuthChangeEvent.signedOut, null));
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
