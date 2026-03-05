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
    child: Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onPressed();
        },
        radius: 20,
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        highlightColor: Colors.transparent,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}
