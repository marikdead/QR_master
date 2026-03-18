import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Color value;
  final ValueChanged<Color> onChanged;

  static const options = <Color>[
    Color(0xFF1A1A1A),
    Color(0xFF4DB6F5),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final c in options) ...[
          _Dot(
            color: c,
            selected: c.value == value.value,
            onTap: () => onChanged(c),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

