import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent back button used across all app bars.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Back',
    button: true,
    child: SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        splashRadius: 18,
        icon: const Icon(
          Icons.chevron_left_rounded,
          size: 24,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onPressed();
        },
      ),
    ),
  );
}
