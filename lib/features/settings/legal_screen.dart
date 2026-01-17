import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/components/components.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _webUrl = 'https://www.prosepal.app/terms.html';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Terms of Use',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppColors.primary),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(_webUrl)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const _LegalSection(
            title: 'Agreement to Terms',
            content:
                'By downloading or using Prosepal, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.',
          ),
          const _LegalSection(
            title: 'Description of Service',
            content:
                'Prosepal is an AI-powered message generation service that helps users create personalized messages for various occasions including birthdays, thank yous, congratulations, and more.',
          ),
          const _LegalSection(
            title: 'User Accounts',
            content:
                'To use Prosepal, you must create an account using Apple Sign In, Google Sign In, or email/password. You are responsible for maintaining the confidentiality of your account credentials.',
          ),
          const _LegalSection(
            title: 'Subscriptions & Payments',
            content:
                '• Free users receive 1 message generation\n'
                '• Pro subscriptions: weekly, monthly, or yearly plans\n'
                '• Payment charged to your Apple ID at purchase\n'
                '• Auto-renews unless cancelled 24 hours before period ends\n'
                '• Manage subscriptions in Apple ID Account Settings',
          ),
          const _LegalSection(
            title: 'Acceptable Use',
            content:
                'You agree not to use Prosepal to:\n'
                '• Generate harmful, abusive, or harassing content\n'
                '• Create spam or unsolicited messages\n'
                '• Violate any applicable laws\n'
                '• Infringe on the rights of others',
          ),
          const _LegalSection(
            title: 'AI-Generated Content',
            content:
                'Messages are created using artificial intelligence. We do not guarantee that generated content will be error-free or appropriate for all situations. You are responsible for reviewing messages before use.',
          ),
          const _LegalSection(
            title: 'Disclaimer',
            content:
                'Prosepal is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free service.',
          ),
          const _LegalSection(
            title: 'Contact',
            content: 'support@prosepal.app',
          ),
          const Gap(AppSpacing.lg),
          Text(
            'Last updated: December 28, 2025',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(_webUrl)),
              child: const Text('View full terms on web'),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _webUrl = 'https://www.prosepal.app/privacy.html';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppColors.primary),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(_webUrl)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const _LegalSection(
            title: 'Overview',
            content:
                'Prosepal is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.',
          ),
          const _LegalSection(
            title: 'Information We Collect',
            content:
                '• Account info: Email address and authentication credentials\n'
                '• Message inputs: Occasion, relationship, tone, and personal details (processed in real-time, not stored)\n'
                '• Usage data: Anonymous statistics to improve our service\n'
                '• Diagnostics: Crash logs to fix bugs',
          ),
          const _LegalSection(
            title: 'How We Use Your Information',
            content:
                '• To provide and maintain our service\n'
                '• To generate personalized messages using AI\n'
                '• To process subscription payments\n'
                '• To improve our app and user experience',
          ),
          const _LegalSection(
            title: 'Third-Party Services',
            content:
                '• Supabase - Authentication\n'
                '• Google AI (Gemini) - Message generation\n'
                '• RevenueCat - Subscription management\n'
                '• Firebase - Analytics and crash reporting',
          ),
          const _LegalSection(
            title: "What We Don't Do",
            content:
                "• We don't sell your data\n"
                "• We don't store generated messages\n"
                "• We don't share data for advertising\n"
                "• We don't use your data for AI training",
          ),
          const _LegalSection(
            title: 'Your Rights',
            content:
                '• Access your personal data\n'
                '• Delete your account and all associated data\n'
                '• Opt out of analytics\n\n'
                'Delete your account anytime from Settings.',
          ),
          const _LegalSection(
            title: 'Contact',
            content: 'support@prosepal.app',
          ),
          const Gap(AppSpacing.lg),
          Text(
            'Last updated: December 28, 2025',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(_webUrl)),
              child: const Text('View full policy on web'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(AppSpacing.sm),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
