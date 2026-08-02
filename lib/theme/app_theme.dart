import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LEP design tokens — the "Docket & Ledger" system.
/// Mirrors the CSS custom properties used in the original web prototype so
/// both platforms stay visually identical:
///   ink / paper / oxblood / brass / line / success / slate.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1C1410);
  static const inkSoft = Color(0xFF5A4F45);
  static const paper = Color(0xFFFBF8F3);
  static const paperDim = Color(0xFFF2EBDD);
  static const oxblood = Color(0xFF7E2430);
  static const oxbloodDeep = Color(0xFF5C1A23);
  static const brass = Color(0xFFA9863F);
  static const brassSoft = Color(0xFFE9DCB8);
  static const line = Color(0xFFE2D6C1);
  static const success = Color(0xFF2F6846);
  static const successBg = Color(0xFFE2EEE3);
  static const slate = Color(0xFF6B7280);
  static const canvas = Color(0xFFEFE7D8);
}

/// Text style helpers. `display` = Fraunces (serif, headings & quotes),
/// `body` = IBM Plex Sans, `mono` = IBM Plex Mono (case refs, citations,
/// timestamps — anything that should read like a docket number).
class AppText {
  AppText._();

  static TextStyle display({
    double size = 18,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
    FontStyle style = FontStyle.normal,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontStyle: style,
      letterSpacing: -0.2,
    );
  }

  static TextStyle body({
    double size = 13.5,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double height = 1.4,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.slate,
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
