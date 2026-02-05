import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/preference_keys.dart';
import 'log_service.dart';

/// Service to handle in-app review requests.
///
/// Triggers review prompt when:
/// - User has completed 1+ generation (has experienced value)
/// - At least 1 day since first app launch
/// - Review hasn't been requested before
///
/// This follows Apple and Google guidelines for non-intrusive review prompts.
/// Timing adjusted for faster feedback from engaged users.
class ReviewService {
  ReviewService(this._prefs);

  final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;
  static const _minGenerationsForReview = 1;
  static const _minDaysBeforeReview = 1;

  // App Store Connect > App Information > Apple ID
  static const _appStoreId = '6757088726';

  /// Records the first launch timestamp if not already set.
  Future<void> recordFirstLaunchIfNeeded() async {
    if (!_prefs.containsKey(PreferenceKeys.reviewFirstLaunch)) {
      await _prefs.setInt(
        PreferenceKeys.reviewFirstLaunch,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Check if we should request a review based on engagement metrics.
  /// Returns true if review was requested.
  Future<bool> checkAndRequestReview(int totalGenerations) async {
    // Already requested once - don't ask again
    final hasRequested =
        _prefs.getBool(PreferenceKeys.reviewHasRequested) ??
        PreferenceKeys.reviewHasRequestedDefault;
    if (hasRequested) return false;

    // Need at least minimum generations
    if (totalGenerations < _minGenerationsForReview) return false;

    // Check if enough days have passed since first launch
    final firstLaunch = _prefs.getInt(PreferenceKeys.reviewFirstLaunch);
    if (firstLaunch != null) {
      final daysSinceFirstLaunch = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(firstLaunch))
          .inDays;
      if (daysSinceFirstLaunch < _minDaysBeforeReview) return false;
    }

    // Add slight delay for better UX (let results screen render first)
    await Future.delayed(const Duration(milliseconds: 800));

    return requestReview();
  }

  /// Request an in-app review if available.
  /// Returns true if the review flow was launched.
  Future<bool> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        Log.info('In-app review not available');
        return false;
      }

      await _inAppReview.requestReview();
      await _prefs.setBool(PreferenceKeys.reviewHasRequested, true);
      Log.info('In-app review requested');
      return true;
    } on Exception catch (e) {
      Log.warning('Error requesting review', {'error': '$e'});
      return false;
    }
  }

  /// Open the app store listing directly (for manual "Rate" button in settings).
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: _appStoreId.isNotEmpty ? _appStoreId : null,
      );
      Log.info('Store listing opened');
    } on Exception catch (e) {
      Log.warning('Error opening store listing', {'error': '$e'});
    }
  }

  /// Check if review has already been requested.
  bool get hasRequestedReview =>
      _prefs.getBool(PreferenceKeys.reviewHasRequested) ??
      PreferenceKeys.reviewHasRequestedDefault;

  /// Reset review state (DEBUG ONLY - for testing).
  @visibleForTesting
  Future<void> resetReviewState() async {
    if (kDebugMode) {
      await _prefs.remove(PreferenceKeys.reviewHasRequested);
      await _prefs.remove(PreferenceKeys.reviewFirstLaunch);
      Log.info('Review state reset');
    }
  }
}
