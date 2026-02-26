import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  /// [isRevenueCatConfigured] - Pass true only if RevenueCat SDK is initialized.
  /// When false, subscription status section is skipped to avoid native crashes.
  ///
  /// Includes:
  /// - App version and device info
  /// - Subscription status (no payment details) - only if RevenueCat configured
  /// - Auth status (no credentials)
  /// - Recent activity log (redacted by default)
  /// - Session info
  ///
  /// Standard report does NOT include:
  /// - Personal message/prompt content
  /// - Payment card info
  /// - Passwords or tokens
  /// - Location data
  ///
  /// Advanced full-details report (explicit user opt-in) may include
  /// message/prompt context and identifiers, but still redacts passwords/tokens.
  static Future<String> generateReport({
    bool isRevenueCatConfigured = false,
    bool includeSensitiveLogs = false,
  }) async {
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
    } on Exception catch (e) {
      Log.warning('App info retrieval failed', {'error': '$e'});
      buffer.writeln('Version: Unable to retrieve');
    }
    buffer.writeln();

    // Device info
    buffer.writeln('--- Device Info ---');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Locale: ${Platform.localeName}');
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        buffer.writeln('Model: ${ios.model}');
        buffer.writeln('Device: ${ios.utsname.machine}');
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        buffer.writeln('Model: ${android.model}');
        buffer.writeln('Manufacturer: ${android.manufacturer}');
        buffer.writeln('Device: ${android.device}');
      }
    } on Exception catch (e) {
      Log.warning('Device info retrieval failed', {'error': '$e'});
    }
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
        buffer.writeln(
          'Provider: ${user.appMetadata['provider'] ?? 'unknown'}',
        );
        buffer.writeln(
          'Created: ${user.createdAt.substring(0, 10)}',
        ); // Just date, not time
      } else {
        buffer.writeln('Signed In: No');
      }
    } on Exception catch (e) {
      Log.warning('Auth status retrieval failed', {'error': '$e'});
      buffer.writeln('Auth Status: Unable to retrieve');
    }
    buffer.writeln();

    // Subscription status (no payment details)
    // Only query RevenueCat if configured to avoid native SDK crashes
    buffer.writeln('--- Subscription Status ---');
    if (isRevenueCatConfigured) {
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
          buffer.writeln('Will Renew: ${entitlement.willRenew ? 'Yes' : 'No'}');
        }

        buffer.writeln(
          'RC User ID: ${_truncateId(customerInfo.originalAppUserId)}',
        );
      } on PlatformException catch (e) {
        Log.warning('Subscription status retrieval failed', {'error': '$e'});
        buffer.writeln('Subscription: Unable to retrieve');
      }
    } else {
      buffer.writeln('Pro Status: Not configured');
    }
    buffer.writeln();

    // Recent logs (includes errors, warnings, and actions)
    buffer.writeln('--- Recent Activity Log ---');
    buffer.writeln(
      Log.getExportableLog(includeSensitive: includeSensitiveLogs),
    );
    buffer.writeln();

    // Footer
    buffer.writeln('=== End of Report ===');
    buffer.writeln();
    if (includeSensitiveLogs) {
      buffer.writeln(
        'This report may include app content context and identifiers. '
        'Passwords/tokens are redacted.',
      );
    } else {
      buffer.writeln(
        'This report contains no personal messages, payment details, or passwords.',
      );
    }
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
