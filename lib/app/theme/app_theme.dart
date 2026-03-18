import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  // ─── Публичный ThemeData приложения ──────────────────────────────────────────
  static ThemeData light() {
    final textTheme = buildAppTextTheme();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.primaryBg,
      secondary: AppColors.secondaryBg,
      error: AppColors.warning,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.secondaryBg,
      textTheme: textTheme,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title1,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Cards (Standard: white + border) ───────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.primaryBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields ────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBg,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),

      // ── Filled Button (Primary, без градиента — используй PrimaryGradientButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minimumSize: const Size.fromHeight(50),
        ),
      ),

      // ── Outlined Button (Secondary: #F6F7FA, без обводки) ───────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.secondaryBg,
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minimumSize: const Size.fromHeight(50),
        ),
      ),

      // ── Text Button (Outline Button: прозрачный + border) ───────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minimumSize: const Size.fromHeight(50),
        ),
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        selectedLabelStyle: AppTextStyles.tabLabel,
        unselectedLabelStyle: AppTextStyles.tabLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ─── Backwards-compat API (старые обращения AppTheme.*) ─────────────────────
  // Цвета
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryBg;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color neutral = Color(0xFFE5E5EA);

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  static const Color border = AppColors.border;

  // Радиусы
  static const double radiusSmall = AppRadius.small;
  static const double radiusMedium = AppRadius.medium;
  static const double radiusLarge = AppRadius.large;
  static const double radiusXL = AppRadius.xl;
}
