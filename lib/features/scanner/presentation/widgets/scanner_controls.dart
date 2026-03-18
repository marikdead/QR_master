import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';

import '../../../../app/theme/app_theme.dart';

class ScannerControls extends StatelessWidget {
  const ScannerControls({
    super.key,
    required this.flashEnabled,
    required this.onFlash,
    required this.onSwitchCamera,
    required this.onGallery,
  });

  final bool flashEnabled;
  final VoidCallback onFlash;
  final VoidCallback onSwitchCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    // Обычная кнопка с IconData
    Widget button({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool active = false,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: active ? AppTheme.primary : AppTheme.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Кнопка с SVG иконкой
    Widget svgButton({
      required String assetPath,
      required String label,
      required VoidCallback onTap,
      bool active = false,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBg, // фон не меняется
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      active ? AppTheme.primary : AppTheme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          svgButton(
            assetPath: 'assets/svg/qr_scanner/flash_icon.svg',
            label: 'Flash',
            onTap: onFlash,
            active: flashEnabled, // синий когда включён
          ),
          button(
            icon: Icons.flip_camera_ios,
            label: 'Switch',
            onTap: onSwitchCamera,
          ),
          svgButton(
            assetPath: 'assets/svg/qr_scanner/gallery_icon.svg',
            label: 'Gallery',
            onTap: onGallery,
          ),
        ],
      ),
    );
  }
}