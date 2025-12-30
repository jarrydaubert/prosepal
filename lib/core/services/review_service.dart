import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle in-app review requests.
///
/// Triggers review prompt when:
/// - User has completed 3+ generations
/// - At least 2 days since first app launch
/// - Review hasn't been requested before
///
/// This follows Apple and Google guidelines for non-intrusive review prompts.
class ReviewService {
  ReviewService(this._prefs);

  final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  static const _hasRequestedReviewKey = 'has_requested_review';
  static const _firstLaunchKey = 'first_launch_timestamp';
  static const _minGenerationsForReview = 3;
  static const _minDaysBeforeReview = 2;

  // TODO: Add your App Store ID after app submission
  // Find it in App Store Connect > App Information > Apple ID
  static const _appStoreId = '';

  /// Records the first launch timestamp if not already set.
  Future<void> recordFirstLaunchIfNeeded() async {
    if (!_prefs.containsKey(_firstLaunchKey)) {
      await _prefs.setInt(
        _firstLaunchKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Check if we should request a review based on engagement metrics.
  /// Returns true if review was requested.
  Future<bool> checkAndRequestReview(int totalGenerations) async {
    // Already requested once - don't ask again
    final hasRequested = _prefs.getBool(_hasRequestedReviewKey) ?? false;
    if (hasRequested) return false;

    // Need at least minimum generations
    if (totalGenerations < _minGenerationsForReview) return false;

    // Check if enough days have passed since first launch
    final firstLaunch = _prefs.getInt(_firstLaunchKey);
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
        if (kDebugMode) {
          debugPrint('In-app review not available');
        }
        return false;
      }

      await _inAppReview.requestReview();
      await _prefs.setBool(_hasRequestedReviewKey, true);

      if (kDebugMode) {
        debugPrint('In-app review requested successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting review: $e');
      }
      return false;
    }
  }

  /// Open the app store listing directly (for manual "Rate" button in settings).
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: _appStoreId.isNotEmpty ? _appStoreId : null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error opening store listing: $e');
      }
    }
  }

  /// Check if review has already been requested.
  bool get hasRequestedReview =>
      _prefs.getBool(_hasRequestedReviewKey) ?? false;

  /// Reset review state (DEBUG ONLY - for testing).
  @visibleForTesting
  Future<void> resetReviewState() async {
    if (kDebugMode) {
      await _prefs.remove(_hasRequestedReviewKey);
      await _prefs.remove(_firstLaunchKey);
      debugPrint('Review state reset');
    }
  }
}
