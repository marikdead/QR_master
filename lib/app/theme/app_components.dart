import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

// ─── Primary Gradient Button ─────────────────────────────────────────────────
// Градиент #7ACBFF → #4DA6FF. Flutter не поддерживает градиент в FilledButton
// нативно, поэтому используй этот виджет для всех primary-действий.
//
// Использование:
//   PrimaryGradientButton(label: 'Продолжить', onPressed: () {}),
//   PrimaryGradientButton(label: 'Загрузка...', onPressed: null, isLoading: true),

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? AppColors.primaryGradient
              : const LinearGradient(
                  colors: [AppColors.textDisabled, AppColors.textDisabled],
                ),
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: enabled ? AppColors.softShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(label, style: AppTextStyles.button),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Secondary Button ────────────────────────────────────────────────────────
// Фон #F6F7FA, без обводки. Удобная обёртка над OutlinedButton из темы.
//
// Использование:
//   SecondaryButton(label: 'Отмена', onPressed: () {}),

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────────────────────
// Прозрачный фон + border #E3E3E3.
//
// Использование:
//   AppOutlineButton(label: 'Подробнее', onPressed: () {}),

class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─── Standard Card ────────────────────────────────────────────────────────────
// Белый фон + border #E3E3E3 + soft shadow.
// Для большинства случаев достаточно стандартного Card из темы,
// но этот виджет добавляет тень из спека.
//
// Использование:
//   AppCard(child: Text('Контент')),

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ─── Secondary Card ───────────────────────────────────────────────────────────
// Фон #F6F7FA, без тени и обводки.
//
// Использование:
//   SecondaryCard(child: Text('Контент')),

class SecondaryCard extends StatelessWidget {
  const SecondaryCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
