import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_interface.dart';

// Google OAuth Client IDs - configured in Google Cloud Console
// Web client ID is used as serverClientId for ID token validation
const _googleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);
// iOS client ID for native sign-in
const _googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '',
);

/// Authentication service using Supabase
/// Supports Apple Sign-In, Google OAuth, and email/password flows
class AuthService implements IAuthService {
  AuthService._();
  static final instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  bool get isLoggedIn => currentUser != null;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
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

  @override
  String? get email => currentUser?.email;

  /// SHA256 hash for nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<AuthResponse> signInWithApple() async {
    // Use generateNonce from sign_in_with_apple 7.x
    final rawNonce = generateNonce();
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

  @override
  Future<AuthResponse> signInWithGoogle() async {
    // Initialize Google Sign In (7.x API - singleton pattern)
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: _googleWebClientId,
      clientId: Platform.isIOS ? _googleIosClientId : null,
    );

    // Try lightweight auth first (silent sign-in if previously authenticated)
    var googleUser = await googleSignIn.attemptLightweightAuthentication();

    // If no existing session, prompt user to sign in
    googleUser ??= await googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw AuthException('Google Sign In failed: No ID token');
    }

    // Get access token for Supabase (requires email/profile scopes)
    final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email', 'profile']) ??
        await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile']);

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signInWithMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? null : 'com.prosepal.prosepal://login-callback',
    );
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
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
