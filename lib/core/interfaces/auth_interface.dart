import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for authentication services
/// Allows mocking in tests without Supabase dependency
abstract class IAuthService {
  /// Current user (null if not logged in)
  User? get currentUser;

  /// Whether user is logged in
  bool get isLoggedIn;

  /// Auth state stream
  Stream<AuthState> get authStateChanges;

  /// User's display name
  String? get displayName;

  /// User's email
  String? get email;

  /// Sign in with Apple (native)
  Future<AuthResponse> signInWithApple();

  /// Sign in with Google (native SDK)
  Future<AuthResponse> signInWithGoogle();

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with Email and Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Send password reset email
  Future<void> resetPassword(String email);

  /// Sign in with magic link (passwordless)
  Future<void> signInWithMagicLink(String email);

  /// Update user's email address
  Future<void> updateEmail(String newEmail);

  /// Update user's password
  Future<void> updatePassword(String newPassword);

  /// Sign out
  Future<void> signOut();

  /// Delete account permanently
  Future<void> deleteAccount();
}
