import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/preference_keys.dart';
import '../../core/interfaces/biometric_interface.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/components/components.dart';
import '../paywall/paywall_sheet.dart';
import '../../shared/theme/app_colors.dart';

// ===========================================================================
// External URLs - centralized for easy updates
// ===========================================================================
const _supportUrl = 'https://www.prosepal.app/support.html';
const _appleSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
const _googleSubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;
  String _biometricType = 'Biometrics';
  bool _isRestoringPurchases = false;
  String _appVersion = '';
  bool _analyticsEnabled = true;

  final InAppReview _inAppReview = InAppReview.instance;

  IBiometricService get _biometricService => ref.read(biometricServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _loadAppVersion();
    _loadAnalyticsSetting();
  }

  Future<void> _loadBiometricSettings() async {
    final biometric = _biometricService;
    final supported = await biometric.isSupported;
    final enabled = await biometric.isEnabled;
    final type = await biometric.biometricTypeName;

    if (mounted) {
      setState(() {
        _biometricsSupported = supported;
        _biometricsEnabled = enabled;
        _biometricType = type;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      Log.warning('Failed to load app version', {'error': '$e'});
      if (mounted) {
        setState(() => _appVersion = 'v1.0.0');
      }
    }
  }

  Future<void> _loadAnalyticsSetting() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool(PreferenceKeys.analyticsEnabled) ?? true;
    if (mounted) {
      setState(() => _analyticsEnabled = enabled);
    }
  }

  Future<void> _toggleAnalytics(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(PreferenceKeys.analyticsEnabled, value);

    // Update both Analytics and Crashlytics collection
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
      Log.info('Analytics collection ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      Log.warning('Failed to update analytics settings', {'error': '$e'});
    }

    if (mounted) {
      setState(() => _analyticsEnabled = value);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    // Require auth for BOTH enable and disable (symmetric security)
    // Prevents unauthorized deactivation on shared/stolen devices
    final reason = value
        ? 'Authenticate to enable $_biometricType'
        : 'Authenticate to disable $_biometricType';
    final result = await _biometricService.authenticate(reason: reason);
    if (!result.success) return;

    await _biometricService.setEnabled(value);
    setState(() => _biometricsEnabled = value);
  }

  Future<void> _restorePurchases() async {
    // Require sign-in for proper account linking
    final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
    if (!isLoggedIn) {
      // Push auth without redirect - it will pop back here on success
      unawaited(context.push('/auth'));
      return;
    }

    // Check if already Pro before restore
    final hadProBefore = ref.read(isProProvider);

    setState(() => _isRestoringPurchases = true);
    try {
      // Identify with RevenueCat before restore to link purchases to user
      final authService = ref.read(authServiceProvider);
      if (authService.currentUser?.id != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(authService.currentUser!.id);
      }

      final restored = await ref
          .read(subscriptionServiceProvider)
          .restorePurchases();

      // Force refresh customer info to update pro status across all screens
      ref.invalidate(customerInfoProvider);

      // Sync usage from server for UI consistency
      await ref.read(usageServiceProvider).syncFromServer();

      if (mounted) {
        String message;
        Color? backgroundColor;
        if (hadProBefore) {
          message = "You're already on Pro!";
          backgroundColor = null;
        } else if (restored) {
          message = 'Purchases restored successfully!';
          backgroundColor = AppColors.success;
        } else {
          message = 'No purchases to restore';
          backgroundColor = null;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      }
    } on PlatformException catch (e) {
      Log.warning('Restore purchases failed', {'error': '$e'});
      if (mounted) {
        final isNetworkError =
            e.code == 'NETWORK_ERROR' ||
            (e.message?.toLowerCase().contains('network') ?? false) ||
            (e.message?.toLowerCase().contains('internet') ?? false) ||
            (e.message?.toLowerCase().contains('offline') ?? false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError
                  ? 'Check your internet connection and try again'
                  : 'Unable to restore purchases. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      Log.warning('Restore purchases failed', {'error': '$e'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to restore purchases. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoringPurchases = false);
    }
  }

  Future<void> _manageSubscription() async {
    // Platform-specific subscription management URLs
    final String url;
    if (Platform.isIOS) {
      url = _appleSubscriptionsUrl;
    } else {
      url = _googleSubscriptionsUrl;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _rateApp() async {
    // Check if in-app review is available (may not be on some devices/builds)
    final isAvailable = await _inAppReview.isAvailable();

    if (isAvailable) {
      // Request in-app review (native prompt, best UX)
      await _inAppReview.requestReview();
    } else {
      // Fallback: open store listing directly
      // iOS requires appStoreId, Android uses package name automatically
      if (Platform.isIOS) {
        await _inAppReview.openStoreListing(appStoreId: '6757088726');
      } else {
        await _inAppReview.openStoreListing();
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      Log.info('Sign out started');
      try {
        // Clear all user-specific data (internet cafe test: leave no trace)
        final authService = ref.read(authServiceProvider);

        // 1. Log out of RevenueCat (unlink user)
        if (authService.currentUser != null) {
          try {
            await ref.read(subscriptionServiceProvider).logOut();
            Log.info('Sign out: RevenueCat logged out');
          } catch (e) {
            Log.warning('Sign out: RevenueCat logout failed', {'error': '$e'});
          }
        }

        // 2. Clear history (personal messages)
        try {
          await ref.read(historyServiceProvider).clearHistory();
          Log.info('Sign out: History cleared');
        } catch (e) {
          Log.warning('Sign out: History clear failed', {'error': '$e'});
        }

        // 3. Mark device as used if user generated any messages (prevents misleading "1 free" after sign out)
        final usageService = ref.read(usageServiceProvider);
        if (usageService.getTotalCount() > 0) {
          try {
            await usageService.markDeviceUsedFreeTier();
            Log.info('Sign out: Device marked as used');
          } catch (e) {
            Log.warning('Sign out: Device marking failed', {'error': '$e'});
          }
        }

        // 4. Clear usage counts (user-specific)
        try {
          await usageService.clearAllUsage();
          Log.info('Sign out: Usage cleared');
        } catch (e) {
          Log.warning('Sign out: Usage clear failed', {'error': '$e'});
        }

        // 5. Disable biometrics (security setting tied to user)
        try {
          await _biometricService.setEnabled(false);
          setState(() => _biometricsEnabled = false);
          Log.info('Sign out: Biometrics disabled');
        } catch (e) {
          Log.warning('Sign out: Biometrics disable failed', {'error': '$e'});
        }

        // 6. Sign out (clears tokens, Google session, logs)
        await authService.signOut();
        Log.info('Sign out completed successfully');

        if (mounted) context.go('/home');
      } catch (e) {
        Log.error('Sign out failed', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign out failed. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportData() async {
    Log.info('Export data started');
    File? tempFile;
    try {
      final exportService = ref.read(dataExportServiceProvider);
      final jsonData = await exportService.exportUserData();
      final filename = exportService.getExportFilename();

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsString(jsonData);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: 'Prosepal Data Export',
        ),
      );

      Log.info('Data export shared successfully');
    } catch (e) {
      Log.error('Data export failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export data. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Clean up temp file
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Two-step confirmation for destructive action (Apple HIG)
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Require re-authentication for sensitive operation
    final reauthResult = await ref
        .read(reauthServiceProvider)
        .requireReauth(
          context: context,
          reason: 'Verify your identity to delete your account.',
        );
    if (!reauthResult.success) {
      if (reauthResult.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reauthResult.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Second confirmation with typed confirmation (Apple HIG)
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(),
    );

    if (finalConfirm ?? false) {
      Log.info('Delete account started');
      try {
        final authService = ref.read(authServiceProvider);

        // 1. Delete account FIRST while JWT is still valid
        // This calls the edge function which needs the access token
        try {
          await authService.deleteAccount();
          Log.info('Delete account: Supabase delete successful');
        } catch (e) {
          Log.error('Delete account: Supabase delete failed', e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete account. Please try again.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // Don't continue if account deletion failed
        }

        // 2. Log out of RevenueCat (after delete, session may be gone)
        try {
          await ref.read(subscriptionServiceProvider).logOut();
          Log.info('Delete account: RevenueCat logged out');
        } catch (e) {
          Log.warning('Delete account: RevenueCat logout failed', {
            'error': '$e',
          });
        }

        // 3. Clear local data (history, usage, biometrics)
        try {
          await ref.read(historyServiceProvider).clearHistory();
          Log.info('Delete account: History cleared');
        } catch (e) {
          Log.warning('Delete account: History clear failed', {'error': '$e'});
        }

        // 4. Mark device as used BEFORE clearing usage (prevents "1 free" after delete)
        final usageService = ref.read(usageServiceProvider);
        if (usageService.getTotalCount() > 0) {
          try {
            await usageService.markDeviceUsedFreeTier();
            Log.info('Delete account: Device marked as used');
          } catch (e) {
            Log.warning('Delete account: Device marking failed', {
              'error': '$e',
            });
          }
        }

        try {
          await usageService.clearAllUsage();
          Log.info('Delete account: Usage cleared');
        } catch (e) {
          Log.warning('Delete account: Usage clear failed', {'error': '$e'});
        }

        try {
          await _biometricService.setEnabled(false);
          Log.info('Delete account: Biometrics disabled');
        } catch (e) {
          Log.warning('Delete account: Biometrics disable failed', {
            'error': '$e',
          });
        }

        Log.info('Delete account completed successfully');

        // Navigate to onboarding for fresh start (not home)
        if (mounted) context.go('/onboarding');
      } catch (e) {
        Log.error('Delete account failed unexpectedly', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occurred. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final usageService = ref.watch(usageServiceProvider);
    final totalGenerated = usageService.getTotalCount();

    // Watch auth state to rebuild when sign in/out occurs
    ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final userEmail = authService.email;
    final userName = authService.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: _BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          // Account section
          const SectionHeader('Account'),
          if (isLoggedIn)
            _AccountCard(userName: userName, userEmail: userEmail, isPro: isPro)
          else
            SettingsTile(
              leading: const Icon(
                Icons.person_add_outlined,
                color: AppColors.primary,
              ),
              title: 'Sign In / Create Account',
              subtitle: 'Save your subscription and preferences',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () => context.push('/auth'),
            ),
          const SizedBox(height: 20),

          // Subscription section
          const SectionHeader('Subscription'),
          SettingsTile(
            leading: Icon(
              isPro ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isPro ? Colors.amber : AppColors.textSecondary,
            ),
            title: isPro ? 'Prosepal Pro' : 'Free Plan',
            subtitle: isPro
                ? '500 messages/month'
                : '${usageService.getRemainingFree()} free messages remaining',
            trailing: isPro
                ? null
                : _UpgradeButton(
                    onPressed: () {
                      // Always show paywall - it has inline auth
                      showPaywall(context, source: 'settings');
                    },
                  ),
          ),
          if (isPro)
            SettingsTile(
              leading: const Icon(
                Icons.credit_card_outlined,
                color: AppColors.textSecondary,
              ),
              title: 'Manage Subscription',
              onTap: _manageSubscription,
            ),
          Semantics(
            label: 'Restore previous purchases',
            hint:
                'Tap to restore your Pro subscription if you reinstalled the app',
            button: true,
            child: SettingsTile(
              leading: _isRestoringPurchases
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                    ),
              title: 'Restore Purchases',
              subtitle: 'Reinstalled? Restore your Pro subscription',
              onTap: _isRestoringPurchases ? null : _restorePurchases,
            ),
          ),

          // Security section (only for signed-in users to prevent lockout)
          if (_biometricsSupported && isLoggedIn) ...[
            const SectionHeader('Security'),
            SettingsTile(
              leading: Icon(
                _biometricType == 'Face ID' ? Icons.face : Icons.fingerprint,
                color: AppColors.textSecondary,
              ),
              title: _biometricType,
              subtitle: 'Require to open app',
              trailing: Switch.adaptive(
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
              ),
            ),
          ],

          // Stats section
          const SectionHeader('Your Stats'),
          _StatsCard(totalGenerated: totalGenerated),

          // Support section
          const SectionHeader('Support'),
          SettingsTile(
            leading: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Help & FAQ',
            onTap: () async {
              final uri = Uri.parse(_supportUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          SettingsTile(
            leading: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Send Feedback',
            subtitle: 'Questions, bugs, or feature requests',
            onTap: () => context.pushNamed('feedback'),
          ),
          Semantics(
            label: 'Rate Prosepal in the app store',
            button: true,
            child: SettingsTile(
              leading: const Icon(
                Icons.star_outline_rounded,
                color: AppColors.textSecondary,
              ),
              title: 'Rate Prosepal',
              subtitle: 'Love the app? Leave a review!',
              onTap: _rateApp,
            ),
          ),

          // Legal section
          const SectionHeader('Legal'),
          SettingsTile(
            leading: const Icon(
              Icons.description_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Terms of Service',
            onTap: () => context.pushNamed('terms'),
          ),
          SettingsTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Privacy Policy',
            onTap: () => context.pushNamed('privacy'),
          ),
          SettingsTile(
            leading: const Icon(
              Icons.analytics_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Analytics & Crash Reports',
            subtitle: _analyticsEnabled
                ? 'Help improve Prosepal'
                : 'Disabled - no data collected',
            trailing: Switch.adaptive(
              value: _analyticsEnabled,
              onChanged: _toggleAnalytics,
            ),
          ),

          // Account actions (only show if signed in)
          if (isLoggedIn) ...[
            const SectionHeader('Account Actions'),
            SettingsTile(
              leading: const Icon(
                Icons.download_rounded,
                color: AppColors.textSecondary,
              ),
              title: 'Export My Data',
              subtitle: 'Download a copy of your data',
              onTap: _exportData,
            ),
            SettingsTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: 'Sign Out',
              titleColor: AppColors.error,
              onTap: _signOut,
            ),
            SettingsTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
              title: 'Delete Account',
              titleColor: AppColors.error,
              subtitle: 'Permanently delete your account and data',
              onTap: _deleteAccount,
            ),
          ],

          // App info footer
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Prosepal ${_appVersion.isNotEmpty ? _appVersion : ""}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () {
          onPressed();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.userName,
    required this.userEmail,
    required this.isPro,
  });

  final String? userName;
  final String? userEmail;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Account: ${userName ?? userEmail ?? "User"}${isPro ? ", Pro subscriber" : ""}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPro ? Colors.amber : AppColors.primary,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isPro
                    ? Colors.amber.withValues(alpha: 0.15)
                    : AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPro ? Colors.amber : AppColors.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    color: isPro ? Colors.amber.shade800 : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.shade700,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (userEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      userEmail!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Text(
          'Upgrade',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.totalGenerated});

  final int totalGenerated;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$totalGenerated messages generated all time',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalGenerated messages generated',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All time',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful dialog for delete confirmation with typed input
class _DeleteConfirmationDialog extends StatefulWidget {
  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text.trim().toUpperCase() == 'DELETE';
      if (matches != _canDelete) {
        setState(() => _canDelete = matches);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you absolutely sure?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You will lose:'),
            const SizedBox(height: 8),
            const Text('• All your generated messages'),
            const Text('• Your account and preferences'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active subscriptions are not automatically cancelled. '
                      'Manage subscriptions in your device Settings.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type DELETE to confirm:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          child: Text(
            'Delete My Account',
            style: TextStyle(color: _canDelete ? AppColors.error : Colors.grey),
          ),
        ),
      ],
    );
  }
}
