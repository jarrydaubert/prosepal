import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _webUrl = 'https://www.prosepal.app/terms.html';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Use'),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(_webUrl)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _LegalSection(
            title: 'Agreement to Terms',
            content:
                'By downloading or using Prosepal, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.',
          ),
          _LegalSection(
            title: 'Description of Service',
            content:
                'Prosepal is an AI-powered message generation service that helps users create personalized messages for various occasions including birthdays, thank yous, congratulations, and more.',
          ),
          _LegalSection(
            title: 'User Accounts',
            content:
                'To use Prosepal, you must create an account using Apple Sign In, Google Sign In, or email/password. You are responsible for maintaining the confidentiality of your account credentials.',
          ),
          _LegalSection(
            title: 'Subscriptions & Payments',
            content:
                '• Free users receive 3 message generations\n'
                '• Pro subscriptions: weekly, monthly, or yearly plans\n'
                '• Payment charged to your Apple ID at purchase\n'
                '• Auto-renews unless cancelled 24 hours before period ends\n'
                '• Manage subscriptions in Apple ID Account Settings',
          ),
          _LegalSection(
            title: 'Acceptable Use',
            content:
                'You agree not to use Prosepal to:\n'
                '• Generate harmful, abusive, or harassing content\n'
                '• Create spam or unsolicited messages\n'
                '• Violate any applicable laws\n'
                '• Infringe on the rights of others',
          ),
          _LegalSection(
            title: 'AI-Generated Content',
            content:
                'Messages are created using artificial intelligence. We do not guarantee that generated content will be error-free or appropriate for all situations. You are responsible for reviewing messages before use.',
          ),
          _LegalSection(
            title: 'Disclaimer',
            content:
                'Prosepal is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free service.',
          ),
          _LegalSection(
            title: 'Contact',
            content: 'support@prosepal.app',
          ),
          Gap(AppSpacing.lg),
          Text(
            'Last updated: December 28, 2025',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          Gap(AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(_webUrl)),
              child: Text('View full terms on web'),
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
      appBar: AppBar(
        title: Text('Privacy Policy'),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(_webUrl)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _LegalSection(
            title: 'Overview',
            content:
                'Prosepal is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.',
          ),
          _LegalSection(
            title: 'Information We Collect',
            content:
                '• Account info: Email address and authentication credentials\n'
                '• Message inputs: Occasion, relationship, tone, and personal details (processed in real-time, not stored)\n'
                '• Usage data: Anonymous statistics to improve our service\n'
                '• Diagnostics: Crash logs to fix bugs',
          ),
          _LegalSection(
            title: 'How We Use Your Information',
            content:
                '• To provide and maintain our service\n'
                '• To generate personalized messages using AI\n'
                '• To process subscription payments\n'
                '• To improve our app and user experience',
          ),
          _LegalSection(
            title: 'Third-Party Services',
            content:
                '• Supabase - Authentication\n'
                '• Google AI (Gemini) - Message generation\n'
                '• RevenueCat - Subscription management\n'
                '• Firebase - Analytics and crash reporting',
          ),
          _LegalSection(
            title: 'What We Don\'t Do',
            content:
                '• We don\'t sell your data\n'
                '• We don\'t store generated messages\n'
                '• We don\'t share data for advertising\n'
                '• We don\'t use your data for AI training',
          ),
          _LegalSection(
            title: 'Your Rights',
            content:
                '• Access your personal data\n'
                '• Delete your account and all associated data\n'
                '• Opt out of analytics\n\n'
                'Delete your account anytime from Settings.',
          ),
          _LegalSection(
            title: 'Contact',
            content: 'support@prosepal.app',
          ),
          Gap(AppSpacing.lg),
          Text(
            'Last updated: December 28, 2025',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          Gap(AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse(_webUrl)),
              child: Text('View full policy on web'),
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
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
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
          Gap(AppSpacing.sm),
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
