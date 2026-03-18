import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ─── Large Title — 34px / Bold (700) ─────────────────────────────────────────
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ─── Title 1 — 28px / Bold (700) ─────────────────────────────────────────────
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ─── Title 2 — 22px / Semibold (600) ─────────────────────────────────────────
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Body / Paragraph — 17px / Regular (400) ─────────────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.47,
  );

  // ─── Caption / Small — 15px / Regular (400) ──────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.47,
  );

  // ─── Button Text — 17px / Semibold (600) ─────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.0,
  );

  // ─── Tab Bar Label — 10px / Medium (500) ─────────────────────────────────────
  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
}

abstract final class AppRadius {
  static const double small  = 8.0;
  static const double medium = 12.0;
  static const double large  = 16.0;
  static const double xl     = 24.0;
}

/// Готовый [TextTheme] для передачи в [ThemeData.textTheme].
TextTheme buildAppTextTheme() {
  return Typography.material2021().black.copyWith(
    displayMedium: AppTextStyles.largeTitle,  // Large Title
    headlineLarge: AppTextStyles.title1,       // Title 1
    headlineMedium: AppTextStyles.title2,      // Title 2
    bodyLarge: AppTextStyles.body,             // Body
    bodyMedium: AppTextStyles.caption,         // Caption
    labelLarge: AppTextStyles.button,          // Button
    labelSmall: AppTextStyles.tabLabel,        // Tab Bar
  );
}
