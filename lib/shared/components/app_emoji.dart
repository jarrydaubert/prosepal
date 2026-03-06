import 'package:flutter/material.dart';

/// Renders emoji glyphs with consistent centering across platforms.
class AppEmoji extends StatelessWidget {
  const AppEmoji({super.key, required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Center(
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        maxLines: 1,
        strutStyle: StrutStyle(
          fontSize: size,
          height: 1,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: size,
          height: 1,
          fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
        ),
      ),
    ),
  );
}
