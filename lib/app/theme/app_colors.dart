import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Primary Backgrounds ─────────────────────────────────────────────────────
  static const Color primaryBg   = Color(0xFFFFFFFF);
  static const Color secondaryBg = Color(0xFFF6F7FA);

  // ─── Accent ──────────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF7ACBFF);
  static const Color primaryDark = Color(0xFF4DA6FF); // gradient end
  static const Color success     = Color(0xFF77C97E);
  static const Color warning     = Color(0xFFFFB86C);

  // ─── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textDisabled  = Color(0xFFB0B0B0);

  // ─── Border ──────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE3E3E3);

  // ─── Shadows ─────────────────────────────────────────────────────────────────
  /// 0 4px 16px rgba(0,0,0,0.06)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// 0 8px 24px rgba(0,0,0,0.08)
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
