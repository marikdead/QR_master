import 'package:flutter/widgets.dart';

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    this.description,
    this.assetImagePath,
    this.previewBuilder,
  });

  final String title;
  final String subtitle;
  final String? description;
  final String? assetImagePath;
  final WidgetBuilder? previewBuilder;
}

