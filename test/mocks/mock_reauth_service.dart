import 'package:flutter/material.dart';
import 'package:prosepal/core/services/reauth_service.dart';

/// Mock implementation of ReauthService for testing
///
/// Does not extend ReauthService to avoid constructor complications.
/// Implements the same interface pattern.
class MockReauthService {
  MockReauthService({
    this.shouldRequireReauth = false,
    this.reauthResult = const ReauthResult(success: true),
  });

  /// Whether re-auth should be required
  final bool shouldRequireReauth;

  /// The result to return from requireReauth
  final ReauthResult reauthResult;

  bool get isReauthRequired => shouldRequireReauth;

  Future<ReauthResult> requireReauth({
    required BuildContext context,
    required String reason,
  }) async {
    if (!shouldRequireReauth) {
      return const ReauthResult(success: true);
    }
    return reauthResult;
  }

  void markReauthenticated() {
    // No-op in mock
  }
}
