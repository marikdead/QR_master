import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/qr_content_type.dart';

class ContentTypeSelector extends StatelessWidget {
  const ContentTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final QrContentType value;
  final ValueChanged<QrContentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = QrContentType.values;
    final firstRow = types.take(3).toList();
    final lastRow = types.skip(3).toList();

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < firstRow.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _TypeCard(type: firstRow[i], active: firstRow[i] == value, onTap: () => onChanged(firstRow[i]))),
            ],
          ],
        ),
        if (lastRow.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < lastRow.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _TypeCard(type: lastRow[i], active: lastRow[i] == value, onTap: () => onChanged(lastRow[i]))),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.active, required this.onTap});
  final QrContentType type;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      QrContentType.url     => Icons.link,
      QrContentType.text    => Icons.text_fields,
      QrContentType.contact => Icons.person,
      QrContentType.wifi    => Icons.wifi,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

