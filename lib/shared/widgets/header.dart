import 'package:flutter/material.dart';
import 'package:qr_code_scanner/app/theme/app_typography.dart';

import '../../../../app/theme/app_colors.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.primaryBg,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 28,    // ← увеличь это значение по вкусу
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.title1,
            ),
            if (onClose != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }
}