import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/interfaces/biometric_interface.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/molecules/molecules.dart';
import '../../shared/theme/app_colors.dart';

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

  final InAppReview _inAppReview = InAppReview.instance;

  IBiometricService get _biometricService => ref.read(biometricServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _loadAppVersion();
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

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final result = await _biometricService.authenticate(
        reason: 'Authenticate to enable $_biometricType',
      );
      if (!result.success) return;
    }

    await _biometricService.setEnabled(value);
    setState(() => _biometricsEnabled = value);
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoringPurchases = true);
    try {
      final restored = await ref
          .read(subscriptionServiceProvider)
          .restorePurchases();
      
      // Force refresh customer info to update pro status across all screens
      ref.invalidate(customerInfoProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Purchases restored successfully!'
                  : 'No purchases to restore',
            ),
            backgroundColor: restored ? AppColors.success : null,
          ),
        );
      }
    } catch (e) {
      Log.warning('Restore purchases failed', {'error': '$e'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore purchases')),
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
      url = 'https://apps.apple.com/account/subscriptions';
    } else {
      // Android Play Store subscriptions
      url = 'https://play.google.com/store/account/subscriptions';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _rateApp() async {
    // Opens the app store listing for rating
    await _inAppReview.openStoreListing(
      appStoreId: '', // Add App Store ID when available
    );
  }

  Future<void> _exportDebugLog() async {
    Log.info('Export debug log requested');
    
    final log = Log.getExportableLog();
    
    // Share as text (user can save or send to support)
    await SharePlus.instance.share(
      ShareParams(
        text: log,
        subject: 'Prosepal Debug Log',
      ),
    );
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
      // Only log out of RevenueCat if user is authenticated (not anonymous)
      final authService = ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        try {
          await ref.read(subscriptionServiceProvider).logOut();
        } catch (e) {
          // Ignore RevenueCat logout errors for anonymous users
          Log.warning('RevenueCat logout skipped', {'reason': 'anonymous user'});
        }
      }
      await authService.signOut();
      if (mounted) context.go('/home');
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

    // Second confirmation with explicit action
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You will lose:'),
            SizedBox(height: 8),
            Text('• All your generated messages'),
            Text('• Your account and preferences'),
            Text('• Any remaining subscription time'),
            SizedBox(height: 16),
            Text(
              'Type "DELETE" to confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete My Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm ?? false) {
      // Only log out of RevenueCat if user is authenticated
      final authService = ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        try {
          await ref.read(subscriptionServiceProvider).logOut();
        } catch (e) {
          Log.warning('RevenueCat logout skipped during delete', {'error': '$e'});
        }
      }
      await authService.deleteAccount();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final usageService = ref.watch(usageServiceProvider);
    final totalGenerated = usageService.getTotalCount();
    final authService = ref.watch(authServiceProvider);
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
          if (userEmail != null)
            _AccountCard(userName: userName, userEmail: userEmail, isPro: isPro)
          else
            SettingsTile(
              leading: const Icon(
                Icons.person_add_outlined,
                color: AppColors.primary,
              ),
              title: 'Sign In / Create Account',
              subtitle: 'Sync your messages across devices',
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
                : _UpgradeButton(onPressed: () => context.pushNamed('paywall')),
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

          // Security section
          if (_biometricsSupported) ...[
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
              final uri = Uri.parse('https://www.prosepal.app/support.html');
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
          SettingsTile(
            leading: const Icon(
              Icons.bug_report_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Export Debug Log',
            subtitle: 'Share with support if something\'s not working',
            onTap: _exportDebugLog,
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

          // Account actions (only show if signed in)
          if (userEmail != null) ...[
            const SectionHeader('Account Actions'),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
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
          HapticFeedback.lightImpact();
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
      label: 'Account: ${userName ?? userEmail ?? "User"}${isPro ? ", Pro subscriber" : ""}',
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
        HapticFeedback.lightImpact();
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
