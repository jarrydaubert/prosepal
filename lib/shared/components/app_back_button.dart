import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/keyboard_utils.dart';

/// Consistent back button used across all app bars.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Back',
    button: true,
    child: SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        splashRadius: 16,
        icon: const Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          dismissKeyboard(context);
          onPressed();
        },
      ),
    ),
  );
}
