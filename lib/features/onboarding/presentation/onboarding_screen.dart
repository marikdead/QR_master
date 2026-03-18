import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';

import '../../../app/theme/app_components.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_page_model.dart';
import 'widgets/onboarding_page.dart';
import '../../../app/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _index = 0;

  final _pages = <OnboardingPageModel>[
    const OnboardingPageModel(
      title: 'Welcome',
      subtitle: 'Scan, Create & Manage QR Codes Easily',
      assetImagePath: 'assets/svg/onboarding/onboarding-1.svg',
    ),
    const OnboardingPageModel(
      title: 'Scan QR Codes',
      subtitle: 'Quickly Scan Any QR Code',
      description: 'Align QR codes in frame and get instant results',
      assetImagePath: 'assets/svg/onboarding/onboarding-2.svg',
    ),
    OnboardingPageModel(
      title: 'Create QR Codes',
      subtitle: 'Generate QR Codes Instantly',
      description: 'Enter URL, text, or contact info and get your custom QR',
      previewBuilder: (context) => _CreateQrPreview(),
    ),
    OnboardingPageModel(
      title: 'Manage & Share',
      subtitle: 'Save, Share, and Track All Your QR Codes',
      description: 'Access My QR Codes and History anytime',
      previewBuilder: (context) => _LibraryPreview(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await injector<OnboardingRepository>().setOnboardingShown();
    if (!mounted) return;
    context.go(AppConstants.routeHome);
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F7FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 24,),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => OnboardingPage(model: _pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    _DotsIndicator(count: _pages.length, index: _index),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(isLast ? AppConstants.onboardingGetStarted : AppConstants.onboardingNext),
                      ),
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text(
                            AppConstants.onboardingSkip,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CreateQrPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Website URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _fakeField('https://example.com'),
          const SizedBox(height: 12),
          PrimaryGradientButton(
            label: 'Generate QR Code',
            onPressed: () => {} // или () {} когда кнопка активна
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _fakeField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const Icon(
            Icons.link,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _LibraryPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: List.generate(4, (i) => _qrCard(i)),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(int i) {
    final titles = ['My Website', 'Contact Info', 'My Website', 'Contact Info'];
    final subtitles = ['portfolio.com', 'John Doe vCard', 'portfolio.com', 'John Doe vCard'];
    final dates = ['Dec 15, 2024', 'Dec 12, 2024', 'Dec 15, 2024', 'Dec 12, 2024'];
    final views = [67, 12, 67, 12];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR превью
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/splashscreen/app_icon.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),

          // Информация
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      titles[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.more_horiz, size: 18, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[i],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      dates[i],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      '${views[i]}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}