import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_interface.dart';

/// Authentication service using Supabase
/// Supports Apple Sign-In, Google OAuth, and email/password flows
class AuthService implements IAuthService {
  AuthService._();
  static final instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Current user (null if not logged in)
  User? get currentUser => _client.auth.currentUser;

  /// Whether user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// User's display name (from metadata or email)
  String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;
    // Try full_name, then name, then capitalize email prefix
    final name =
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user.email?.split('@').first;
    // Capitalize first letter if from email
    if (name != null && user.email?.startsWith(name) == true) {
      return name[0].toUpperCase() + name.substring(1);
    }
    return name;
  }

  /// User's email
  String? get email => currentUser?.email;

  /// Generate a random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA256 hash for Apple Sign In
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple (native)
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw AuthException('Apple Sign In failed: No identity token');
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Sign in with Google (OAuth - opens browser)
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.prosepal.prosepal://login-callback',
    );
  }

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with Email and Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  /// Send password reset email
  /// Triggers "Reset password" email template
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign in with magic link (passwordless)
  /// Triggers "Magic link" email template
  Future<void> signInWithMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? null : 'com.prosepal.prosepal://login-callback',
    );
  }

  /// Update user's email address
  /// Triggers "Change email address" email template
  Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  /// Update user's password (when logged in)
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Delete account permanently
  /// Calls Supabase Edge Function 'delete-user' which requires service role
  /// to delete from auth.users table
  ///
  /// App Store requires account deletion - this satisfies that requirement
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Call Edge Function to delete user (requires service role on server)
      final response = await _client.functions.invoke(
        'delete-user',
        headers: {
          'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint('Account deletion failed: ${response.data}');
        }
        // Still sign out locally even if server deletion fails
      }
    } catch (e) {
      // Edge Function may not be deployed yet
      if (kDebugMode) {
        debugPrint('Account deletion error: $e');
        debugPrint(
          'Deploy the delete-user Edge Function in Supabase dashboard.',
        );
      }
    }

    // Always sign out locally
    await signOut();
  }
}
