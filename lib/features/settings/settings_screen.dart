import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final supported = await BiometricService.instance.isSupported;
    final enabled = await BiometricService.instance.isEnabled;
    final type = await BiometricService.instance.biometricTypeName;

    if (mounted) {
      setState(() {
        _biometricsSupported = supported;
        _biometricsEnabled = enabled;
        _biometricType = type;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Authenticate to enable $_biometricType',
      );
      if (!authenticated) return;
    }

    await BiometricService.instance.setEnabled(value);
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
    // Opens Apple's subscription management
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(subscriptionServiceProvider).logOut();
      await AuthService.instance.signOut();
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _deleteAccount() async {
    // Two-step confirmation for destructive action (Apple HIG)
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continue', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation with explicit action
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you absolutely sure?'),
        content: Column(
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
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete My Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm == true) {
      await ref.read(subscriptionServiceProvider).logOut();
      await AuthService.instance.deleteAccount();
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final usageService = ref.watch(usageServiceProvider);
    final totalGenerated = usageService.getTotalCount();
    final userEmail = AuthService.instance.email;
    final userName = AuthService.instance.displayName;

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Account section (most important - at top per Apple HIG)
          SectionHeader('Account'),
          SettingsTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: userName ?? 'User',
            subtitle: userEmail,
          ),

          // Subscription section
          SectionHeader('Subscription'),
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
                    child: Text('Upgrade'),
                  ),
          ),
          if (isPro)
            SettingsTile(
              leading: Icon(
                Icons.credit_card_outlined,
                color: AppColors.textSecondary,
              ),
              title: 'Manage Subscription',
              onTap: _manageSubscription,
            ),
          SettingsTile(
            leading: _isRestoringPurchases
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            title: 'Restore Purchases',
            subtitle: 'Reinstalled? Restore your Pro subscription',
            onTap: _isRestoringPurchases ? null : _restorePurchases,
          ),

          // Security section
          if (_biometricsSupported) ...[
            SectionHeader('Security'),
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
          SectionHeader('Your Stats'),
          SettingsTile(
            leading: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            title: '$totalGenerated messages generated',
            subtitle: 'All time',
          ),

          // Support section
          SectionHeader('Support'),
          SettingsTile(
            leading: Icon(
              Icons.help_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Help & FAQ',
            onTap: () {
              // TODO: Open help
            },
          ),
          SettingsTile(
            leading: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Send Feedback',
            subtitle: 'Questions, bugs, or feature requests',
            onTap: () => context.pushNamed('feedback'),
          ),
          SettingsTile(
            leading: Icon(
              Icons.star_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: 'Rate Prosepal',
            subtitle: 'Love the app? Leave a review!',
            onTap: () {
              // TODO: Open app store review
            },
          ),

          // Legal section
          SectionHeader('Legal'),
          SettingsTile(
            leading: Icon(
              Icons.description_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Terms of Service',
            onTap: () async {
              final uri = Uri.parse('https://prosepal.app/terms');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              }
            },
          ),
          SettingsTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.textSecondary,
            ),
            title: 'Privacy Policy',
            onTap: () async {
              final uri = Uri.parse('https://prosepal.app/privacy');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              }
            },
          ),

          // Account actions (destructive actions at bottom per Apple HIG)
          SectionHeader('Account Actions'),
          SettingsTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: 'Sign Out',
            titleColor: AppColors.error,
            onTap: _signOut,
          ),
          SettingsTile(
            leading: Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: 'Delete Account',
            titleColor: AppColors.error,
            subtitle: 'Permanently delete your account and data',
            onTap: _deleteAccount,
          ),

          // App info footer
          Gap(AppSpacing.xl),
          Center(
            child: Text(
              'Prosepal v1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ),
          Gap(AppSpacing.xxl),
        ],
      ),
    );
  }
}

// Now using shared molecules:
// - SectionHeader from shared/molecules/section_header.dart
// - SettingsTile from shared/molecules/settings_tile.dart
