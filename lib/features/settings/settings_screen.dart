import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
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
      // Authenticate before enabling
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Authenticate to enable $_biometricType',
      );
      if (!authenticated) return;
    }
    
    await BiometricService.instance.setEnabled(value);
    setState(() => _biometricsEnabled = value);
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
      await AuthService.instance.signOut();
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
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Subscription status
          _SettingsCard(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isPro
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro ? Icons.star : Icons.person_outline,
                    color: isPro ? AppColors.accentDark : AppColors.primary,
                  ),
                ),
                Gap(AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'Prosepal Pro' : 'Free Plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isPro
                            ? 'Unlimited messages'
                            : '${usageService.getRemainingFree()} free messages left today',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!isPro)
                  TextButton(
                    onPressed: () => context.pushNamed('paywall'),
                    child: Text('Upgrade'),
                  ),
              ],
            ),
          ),

          Gap(AppSpacing.lg),

          // Account section
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Gap(AppSpacing.sm),
          _SettingsCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (userEmail != null)
                            Text(
                              userEmail,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap(AppSpacing.md),
                Divider(height: 1),
                Gap(AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _signOut,
                    icon: Icon(Icons.logout, size: 20),
                    label: Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Gap(AppSpacing.lg),

          // Security section
          if (_biometricsSupported) ...[
            Text(
              'Security',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Gap(AppSpacing.sm),
            _SettingsCard(
              child: Row(
                children: [
                  Icon(
                    _biometricType == 'Face ID' ? Icons.face : Icons.fingerprint,
                    color: AppColors.textSecondary,
                  ),
                  Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _biometricType,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Require $_biometricType to open app',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _biometricsEnabled,
                    onChanged: _toggleBiometrics,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            Gap(AppSpacing.lg),
          ],

          // Stats
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Stats',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Gap(AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.auto_awesome,
                        value: '$totalGenerated',
                        label: 'Messages generated',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Gap(AppSpacing.lg),

          // Support section
          Text(
            'Support',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Gap(AppSpacing.sm),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  onTap: () {
                    // TODO: Open help
                  },
                ),
                Divider(height: 1),
                _SettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Contact Us',
                  onTap: () async {
                    final uri = Uri.parse('mailto:support@prosepal.app');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                Divider(height: 1),
                _SettingsRow(
                  icon: Icons.star_outline,
                  title: 'Rate Prosepal',
                  onTap: () {
                    // TODO: Open app store
                  },
                ),
              ],
            ),
          ),

          Gap(AppSpacing.lg),

          // Legal section
          Text(
            'Legal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Gap(AppSpacing.sm),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    // TODO: Open terms
                  },
                ),
                Divider(height: 1),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    // TODO: Open privacy
                  },
                ),
              ],
            ),
          ),

          Gap(AppSpacing.lg),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Prosepal v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
                Gap(AppSpacing.xs),
                Text(
                  'Made with ❤️',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),

          Gap(AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            Gap(AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        Gap(AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
