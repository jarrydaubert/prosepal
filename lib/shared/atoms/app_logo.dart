import 'package:flutter/material.dart';

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
