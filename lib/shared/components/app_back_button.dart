import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent back button used across all app bars.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () {
      FocusManager.instance.primaryFocus?.unfocus();
      onPressed();
    },
    tooltip: 'Back',
    icon: const Icon(Icons.chevron_left_rounded, size: 24),
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      fixedSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      foregroundColor: AppColors.textPrimary,
      backgroundColor: Colors.transparent,
    ),
  );
}
