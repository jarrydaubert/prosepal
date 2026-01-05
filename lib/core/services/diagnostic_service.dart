import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_log_service.dart';
import 'log_service.dart';

/// Diagnostic service for generating user-shareable support reports
///
/// Privacy-compliant: User must explicitly share the report (via email/copy).
/// No data is sent automatically - user controls what gets shared.
///
/// Usage:
/// ```dart
/// final report = await DiagnosticService.generateReport();
/// // Show to user, let them share via email or copy
/// ```
abstract final class DiagnosticService {
  /// Generate a diagnostic report for support
  ///
  /// Includes:
  /// - App version and device info
  /// - Subscription status (no payment details)
  /// - Auth status (no credentials)
  /// - Recent error log
  /// - Session info
  ///
  /// Does NOT include:
  /// - Personal messages or content
  /// - Payment card info
  /// - Passwords or tokens
  /// - Location data
  static Future<String> generateReport() async {
    final buffer = StringBuffer();

    buffer.writeln('=== Prosepal Diagnostic Report ===');
    buffer.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln();

    // App info
    buffer.writeln('--- App Info ---');
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      buffer.writeln('Version: ${packageInfo.version}');
      buffer.writeln('Build: ${packageInfo.buildNumber}');
      buffer.writeln('Package: ${packageInfo.packageName}');
    } catch (e) {
      buffer.writeln('Version: Unable to retrieve');
    }
    buffer.writeln();

    // Device info
    buffer.writeln('--- Device Info ---');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Locale: ${Platform.localeName}');
    if (kDebugMode) {
      buffer.writeln('Build Mode: Debug');
    } else if (kProfileMode) {
      buffer.writeln('Build Mode: Profile');
    } else {
      buffer.writeln('Build Mode: Release');
    }
    buffer.writeln();

    // Auth status (no credentials)
    buffer.writeln('--- Auth Status ---');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        buffer.writeln('Signed In: Yes');
        buffer.writeln('User ID: ${_truncateId(user.id)}');
        buffer.writeln('Provider: ${user.appMetadata['provider'] ?? 'unknown'}');
        buffer.writeln(
          'Created: ${user.createdAt.substring(0, 10)}',
        ); // Just date, not time
      } else {
        buffer.writeln('Signed In: No');
      }
    } catch (e) {
      buffer.writeln('Auth Status: Unable to retrieve');
    }
    buffer.writeln();

    // Subscription status (no payment details)
    buffer.writeln('--- Subscription Status ---');
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive = customerInfo.entitlements.active.isNotEmpty;
      buffer.writeln('Pro Status: ${isActive ? 'Active' : 'Free'}');

      if (isActive) {
        final entitlement = customerInfo.entitlements.active.values.first;
        buffer.writeln('Product: ${entitlement.productIdentifier}');
        if (entitlement.expirationDate != null) {
          // Just show date, not full timestamp
          buffer.writeln(
            'Expires: ${entitlement.expirationDate!.substring(0, 10)}',
          );
        }
        buffer.writeln(
          'Will Renew: ${entitlement.willRenew ? 'Yes' : 'No'}',
        );
      }

      buffer.writeln('RC User ID: ${_truncateId(customerInfo.originalAppUserId)}');
    } catch (e) {
      buffer.writeln('Subscription: Unable to retrieve');
    }
    buffer.writeln();

    // Recent errors
    buffer.writeln('--- Recent Errors ---');
    final errorLog = ErrorLogService.instance.getFormattedLog();
    buffer.writeln(errorLog);
    buffer.writeln();

    // User action breadcrumbs (last 50 actions)
    buffer.writeln('--- Recent Actions ---');
    final breadcrumbs = Log.getRecentBreadcrumbs(count: 50);
    if (breadcrumbs.isEmpty) {
      buffer.writeln('No actions recorded');
    } else {
      for (final crumb in breadcrumbs) {
        buffer.writeln(crumb);
      }
    }
    buffer.writeln();

    // Footer
    buffer.writeln('=== End of Report ===');
    buffer.writeln();
    buffer.writeln(
      'This report contains no personal messages, payment details, or passwords.',
    );
    buffer.writeln(
      'Share this with support@prosepal.app to help troubleshoot issues.',
    );

    final report = buffer.toString();

    // Log that a diagnostic was generated (for Crashlytics context)
    Log.info('Diagnostic report generated');

    return report;
  }

  /// Truncate IDs for privacy (show first 8 chars)
  static String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}
