import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../onboarding_page_model.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.model});

  final OnboardingPageModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            model.title,
            style: AppTextStyles.largeTitle,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: _buildVisual(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            model.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.title1
          ),
          if (model.description != null) ...[
            const SizedBox(height: 10),
            Text(
              model.description!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisual(BuildContext context) {
    if (model.previewBuilder != null) {
      return model.previewBuilder!(context);
    }
    if (model.assetImagePath != null) {
      return SvgPicture.asset(
        model.assetImagePath!,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Icon(Icons.qr_code_2, size: 88, color: AppTheme.primary),
    );
  }
}

