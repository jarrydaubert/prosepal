import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centralized app logo widget
/// Update the asset path here to change logo everywhere
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  static const String assetPath = 'assets/images/logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: size, height: size);
  }
}

/// Styled logo with coral border - used on auth screen and splash/privacy screens
class AppLogoStyled extends StatelessWidget {
  const AppLogoStyled({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(size * 0.4),
        border: Border.all(color: AppColors.primary, width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.36),
        child: AppLogo(size: size - 20),
      ),
    );
  }
}
