import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppDimens {
  // Kid-friendly touch target sizes (Apple/Android guidelines for children: >= 48-56dp)
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 56.0;
  static const double iconButtonSize = 52.0;

  // Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 9999.0;

  // Padding & Spacing
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: const ['Nunito', 'Roboto', 'Arial', 'sans-serif'],
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentGold,
        surface: AppColors.surface,
        error: AppColors.accentRed,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withAlpha(80),
          textStyle: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
