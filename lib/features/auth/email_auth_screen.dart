import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Continue with Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              if (_emailSent) ...[
                // Success state
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: AppColors.success,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent you a magic link.\nTap it to sign in instantly.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => setState(() => _emailSent = false),
                  child: Text('Use a different email'),
                ),
              ] else ...[
                // Email input
                Text(
                  'No password needed',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                SizedBox(height: AppSpacing.lg),
                SupaMagicAuth(
                  redirectUrl: 'com.prosepal.prosepal://login-callback',
                  onSuccess: (response) {
                    setState(() => _emailSent = true);
                  },
                  onError: (error) {
                    final message = error is AuthException 
                        ? error.message 
                        : 'Something went wrong';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
