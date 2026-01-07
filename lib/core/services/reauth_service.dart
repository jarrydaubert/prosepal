import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/biometric_interface.dart';
import 'biometric_service.dart';
import 'log_service.dart';

/// Result of a re-authentication attempt
class ReauthResult {
  const ReauthResult({required this.success, this.errorMessage});

  final bool success;
  final String? errorMessage;

  static const cancelled = ReauthResult(success: false);
}

/// Service for requiring re-authentication before sensitive operations
///
/// Sensitive operations (updateEmail, updatePassword, deleteAccount) should
/// require recent authentication to prevent unauthorized changes on shared
/// or stolen devices.
class ReauthService {
  ReauthService({
    required IBiometricService biometricService,
    required GoTrueClient supabaseAuth,
  }) : _biometricService = biometricService,
       _supabaseAuth = supabaseAuth;

  final IBiometricService _biometricService;
  final GoTrueClient _supabaseAuth;

  /// Maximum time since last authentication before re-auth is required
  static const _reauthTimeout = Duration(minutes: 5);

  DateTime? _lastReauthAt;

  /// Check if re-authentication is required
  ///
  /// Returns true if the user hasn't authenticated recently (within timeout).
  bool get isReauthRequired {
    final lastAuth = _lastReauthAt ?? _getSessionCreatedAt();
    if (lastAuth == null) return true;

    final elapsed = DateTime.now().difference(lastAuth);
    return elapsed > _reauthTimeout;
  }

  /// Get when the current session was created (user signed in)
  DateTime? _getSessionCreatedAt() {
    final session = _supabaseAuth.currentSession;
    if (session == null) return null;

    // Supabase stores createdAt as seconds since epoch
    final createdAt = session.user.createdAt;
    return DateTime.tryParse(createdAt);
  }

  /// Mark that re-authentication just occurred
  void markReauthenticated() {
    _lastReauthAt = DateTime.now();
  }

  /// Require re-authentication before a sensitive operation
  ///
  /// Shows biometric prompt if available and enabled, otherwise shows
  /// password dialog for email/password users.
  ///
  /// Returns [ReauthResult] indicating success or failure with optional message.
  Future<ReauthResult> requireReauth({
    required BuildContext context,
    required String reason,
  }) async {
    // Check if re-auth is actually needed
    if (!isReauthRequired) {
      Log.info('Re-auth not required - authenticated recently');
      return const ReauthResult(success: true);
    }

    Log.info('Re-auth required', {'reason': reason});

    // Try biometrics first if enabled
    final biometricsEnabled = await _biometricService.isEnabled;
    final biometricsAvailable =
        (await _biometricService.availableBiometrics).isNotEmpty;

    if (biometricsEnabled && biometricsAvailable) {
      final result = await _biometricService.authenticate(reason: reason);
      if (result.success) {
        markReauthenticated();
        Log.info('Re-auth successful via biometrics');
        return const ReauthResult(success: true);
      }
      // Biometrics failed - don't fall back to password for security
      Log.warning('Re-auth failed via biometrics');
      return ReauthResult(
        success: false,
        errorMessage: result.message ?? 'Authentication failed',
      );
    }

    // Check if user has a password (email auth)
    final user = _supabaseAuth.currentUser;
    if (user == null) {
      return const ReauthResult(
        success: false,
        errorMessage: 'Not signed in',
      );
    }

    // Check provider - OAuth users may not have a password
    final identities = user.identities ?? [];
    final hasPasswordAuth = identities.any((i) => i.provider == 'email');

    if (!hasPasswordAuth) {
      // OAuth-only user without biometrics - show confirmation dialog
      if (!context.mounted) return ReauthResult.cancelled;

      final confirmed = await _showConfirmationDialog(
        context: context,
        reason: reason,
      );
      if (confirmed) {
        markReauthenticated();
        Log.info('Re-auth successful via confirmation');
        return const ReauthResult(success: true);
      }
      return ReauthResult.cancelled;
    }

    // Email user - require password
    if (!context.mounted) return ReauthResult.cancelled;

    final password = await _showPasswordDialog(
      context: context,
      reason: reason,
      email: user.email ?? '',
    );

    if (password == null || password.isEmpty) {
      Log.info('Re-auth cancelled by user');
      return ReauthResult.cancelled;
    }

    // Verify password by attempting sign-in
    try {
      await _supabaseAuth.signInWithPassword(
        email: user.email!,
        password: password,
      );
      markReauthenticated();
      Log.info('Re-auth successful via password');
      return const ReauthResult(success: true);
    } on AuthException catch (e) {
      Log.warning('Re-auth failed via password', {'error': e.message});
      return ReauthResult(
        success: false,
        errorMessage: 'Incorrect password',
      );
    }
  }

  /// Show password entry dialog
  Future<String?> _showPasswordDialog({
    required BuildContext context,
    required String reason,
    required String email,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Identity'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your password for $email',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(controller.text);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog for OAuth users without biometrics
  Future<bool> _showConfirmationDialog({
    required BuildContext context,
    required String reason,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason),
            const SizedBox(height: 16),
            Text(
              'For better security, enable biometrics in Settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
