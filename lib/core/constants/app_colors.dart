import 'package:flutter/material.dart';

class AppColors {
  // Base Color (Background) - Bright Snow (#F6F6F6)
  static const Color ivory = Color(0xFFF6F6F6);
  static const Color ivoryDark = Color(
    0xFFE0E0E0,
  ); // Darker shade for neumorphic shadows

  // Point Color (Action) - Dark Wine (#751013)
  static const Color burgundy = Color(0xFF680F0E);
  static const Color burgundyLight = Color(
    0xFF9A2024,
  ); // Lighter shade for gradients

  // Contrast Colors (Text/Icons)
  static const Color charcoal = Color(0xFF2E2E2E); // Graphite (#2E2E2E)
  static const Color black = Color(0xFF000000); // Strong emphasis
  static const Color grey = Color(0xFF757575); // Valid/Disabled text
  static const Color greyLight = Color(
    0xFFAAAAAA,
  ); // Light grey for placeholders/icons
  static const Color white = Color(0xFFFFFFFF); // Pure white for highlights

  // Neumorphic Shadows
  static const Color shadowLight = Colors.white;
  static const Color shadowDark = Color(0xFFD9D9D9); // Adjusted for #F6F6F6
}
