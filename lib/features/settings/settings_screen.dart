import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/interfaces/biometric_interface.dart';
import '../../core/providers/providers.dart';
import '../../shared/molecules/molecules.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

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
    } catch (_) {
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
      await ref.read(subscriptionServiceProvider).logOut();
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go('/auth');
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
            Gap(AppSpacing.sm),
            Text('• All your generated messages'),
            Text('• Your account and preferences'),
            Text('• Any remaining subscription time'),
            Gap(AppSpacing.md),
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
      await ref.read(subscriptionServiceProvider).logOut();
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) context.go('/auth');
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Gap(AppSpacing.sm),
          // Account section
          const SectionHeader('Account'),
          _buildModernCard(
            context,
            child: _buildAccountHeader(context, userName, userEmail, isPro),
          ),
          const Gap(AppSpacing.lg),

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
                : TextButton(
                    onPressed: () => context.pushNamed('paywall'),
                    child: const Text('Upgrade'),
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
          SettingsTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
            title: '$totalGenerated messages generated',
            subtitle: 'All time',
          ),

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

          // Account actions (destructive actions at bottom per Apple HIG)
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

          // App info footer
          const Gap(AppSpacing.xl),
          Center(
            child: Text(
              'Prosepal ${_appVersion.isNotEmpty ? _appVersion : ""}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint.withValues(alpha: 0.6),
              ),
            ),
          ),
          const Gap(AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Modern card with subtle shadow and rounded corners
  Widget _buildModernCard(BuildContext context, {required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Account header with avatar and pro badge
  Widget _buildAccountHeader(
    BuildContext context,
    String? userName,
    String? userEmail,
    bool isPro,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with glow effect for Pro users
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isPro
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isPro
                  ? Colors.amber.shade100
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (userEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
