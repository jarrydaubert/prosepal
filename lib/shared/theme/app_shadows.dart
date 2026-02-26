import 'package:flutter/material.dart';

/// Shadow tokens for consistent elevation across the app
class AppShadows {
  AppShadows._();

  /// Subtle shadow for cards at rest
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Elevated shadow for modals, FABs, dropdowns
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Pressed/active state shadow
  static const List<BoxShadow> pressed = [
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// No shadow
  static const List<BoxShadow> none = [];
}
