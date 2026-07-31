import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF8B1A1A); // Deep crimson red
  static const Color primaryLight = Color(0xFFB71C1C); // Lighter red (buttons, accents)
  static const Color primaryDark = Color(0xFF5D0000); // Dark red

  // Accent / Secondary
  static const Color accent = Color(0xFFD32F2F); // Vibrant red (CTAs)
  static const Color accentLight = Color(0xFFFDE8E8); // Light pink (card backgrounds)

  // Backgrounds
  static const Color background = Color(0xFFFAF5F5); // Off-white with warm tint
  static const Color surface = Color(0xFFFFFFFF); // White cards
  static const Color surfacePink = Color(0xFFFFF0F0); // Light pink surface

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A); // Near-black
  static const Color textSecondary = Color(0xFF666666); // Grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on red

  // Status
  static const Color success = Color(0xFF2E7D32); // Green (verified, completed)
  static const Color warning = Color(0xFFF57C00); // Orange
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color info = Color(0xFF1565C0); // Blue

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // Chips & Tags
  static const Color chipActive = Color(0xFF8B1A1A);
  static const Color chipInactive = Color(0xFFF5F5F5);
  static const Color tagLabourLaw = Color(0xFFD32F2F);
  static const Color tagConstitutional = Color(0xFF666666);
}
