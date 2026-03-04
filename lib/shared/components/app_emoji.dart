import 'package:flutter/material.dart';

/// Renders emoji glyphs with consistent centering across platforms.
class AppEmoji extends StatelessWidget {
  const AppEmoji({super.key, required this.emoji, required this.size});

  final String emoji;
  final double size;

  static const _fallbackFonts = <String>[
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
  ];

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
          fontSize: size * 0.9,
          height: 1,
          forceStrutHeight: true,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: TextStyle(
          fontSize: size * 0.9,
          height: 1,
          fontFamilyFallback: _fallbackFonts,
        ),
      ),
    ),
  );
}
