import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle _baseFallback = TextStyle(
    fontFamilyFallback: ['Nunito', 'Roboto', 'Arial', 'sans-serif'],
  );

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get mathSymbol => GoogleFonts.plusJakartaSans(
        textStyle: _baseFallback,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      );
}
