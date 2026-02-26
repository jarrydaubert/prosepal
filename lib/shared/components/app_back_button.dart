import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent back button used across all app bars.
/// Matches the primary color scheme with rounded container style.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
      ),
    ),
  );
}
