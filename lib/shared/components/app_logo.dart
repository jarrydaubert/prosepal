import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centralized app logo widget
/// Update the asset path here to change logo everywhere
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  static const String assetPath = 'assets/images/logo.png';

  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset(assetPath, width: size, height: size);
}

/// Styled logo with coral border - used on auth screen and splash/privacy screens
class AppLogoStyled extends StatelessWidget {
  const AppLogoStyled({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
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

/// Splash-specific logo treatment for cleaner first-launch presentation.
class AppLogoSplash extends StatelessWidget {
  const AppLogoSplash({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFFFCE9E7), Color(0xFFF3D8D5)],
      ),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.85),
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(size * 0.16),
      child: AppLogo(size: size * 0.68),
    ),
  );
}
