import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shimmer/shimmer.dart';


import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/appsflyer_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../subscription/data/apphud_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _version;
  static const Duration _stepTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
    unawaited(_loadVersion());
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();

    bool onboardingShown = false;

    try {
      // 1) ATT (iOS) before AppsFlyer
      await _ensureATT().timeout(_stepTimeout);

      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('📦 packageName: ${packageInfo.packageName}');
      debugPrint('📦 appName: ${packageInfo.appName}');
      debugPrint('📦 version: ${packageInfo.version}');

      // 2) AppsFlyer
      final appsflyer = AppsflyerSdk(
        AppsFlyerOptions(
          afDevKey: 'GAgckFyN4yETigBtP4qtRG',
            appId: 'com.nicfuno.sonicforgeflow',
          timeToWaitForATTUserAuthorization: 60,
          showDebug: true
        ),
      );
      final appsFlyerService = AppsFlyerService(appsflyer);
      await appsFlyerService.init().timeout(_stepTimeout);
      if (injector.isRegistered<AppsFlyerService>()) {
        injector.unregister<AppsFlyerService>();
      }
      injector.registerSingleton<AppsFlyerService>(appsFlyerService);

      // 3) Apphud
      final apphud = injector<ApphudRepository>();
      await Apphud.enableDebugLogs();
      await apphud.start(apiKey: 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga').timeout(_stepTimeout);


      // AppsFlyer conversion data -> Apphud attribution (best-effort)
      appsflyer.onInstallConversionData((data) async {
        try {
          final uid = await appsflyer.getAppsFlyerUID();
          final map =
              (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
          await Apphud.setAttribution(
            provider: ApphudAttributionProvider.appsFlyer,
            identifier: uid,
            data: ApphudAttributionData(rawData: map),
          );
        } catch (_) {
          // no-op
        }
      });

      // 4) Subscription (best-effort; never block the app start)
      await apphud.hasPremiumAccess().timeout(_stepTimeout);

      // 5) Onboarding flag
      final onboardingRepo = injector<OnboardingRepository>();
      onboardingShown = onboardingRepo.getOnboardingShown();
    } catch (_) {
      // If any boot step fails/hangs, still proceed to the app.
      final onboardingRepo = injector<OnboardingRepository>();
      onboardingShown = onboardingRepo.getOnboardingShown();
    }

    // Min duration
    final elapsed = DateTime.now().difference(startedAt);
    final left = AppConstants.splashMinDuration - elapsed;
    if (left > Duration.zero) {
      await Future<void>.delayed(left);
    }
    if (!mounted) return;

    context.go(onboardingShown ? AppConstants.routeHome : AppConstants.routeOnboarding);
  }

  Future<void> _ensureATT() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // no-op: ATT not supported on this platform
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: _SplashBackgroundPainter(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7ACBFF),
                        Color(0xFF4DA6FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7ACBFF).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4DA6FF).withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: SvgPicture.asset(
                      'assets/svg/splashscreen/app_icon.svg',
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.splashScanCreateManage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),
                const _AnimatedDots(),
                const SizedBox(height: 10),
                Text(
                  AppConstants.splashLoading,
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
                const Spacer(),
                Text(
                  _version == null
                      ? ''
                      : '${AppConstants.splashVersionPrefix} $_version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.border,
      highlightColor: AppTheme.primary.withValues(alpha: 0.7),
      period: const Duration(milliseconds: 1000),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final active = ((t * 3).floor()) % 3;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final isActive = i == active;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 10 : 8,
                height: isActive ? 10 : 8,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : AppTheme.border,
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Верхний левый
    paint.color = AppTheme.primary.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), size.width * 0.32, paint);

    // Верхний левый маленький
    paint.color = AppTheme.primary.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.25), size.width * 0.15, paint);

    // Верхний правый
    paint.color = AppTheme.warning.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.16), size.width * 0.25, paint);

    // Верхний правый маленький
    paint.color = AppTheme.warning.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.08), size.width * 0.12, paint);

    // Центр левый
    paint.color = AppTheme.success.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.52), size.width * 0.18, paint);

    // Центр правый
    paint.color = AppTheme.primary.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.48), size.width * 0.20, paint);

    // Нижний правый большой
    paint.color = AppTheme.success.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.90), size.width * 0.32, paint);

    // Нижний правый маленький
    paint.color = AppTheme.warning.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.96), size.width * 0.14, paint);

    // Нижний левый
    paint.color = AppTheme.primary.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.88), size.width * 0.22, paint);

    // Нижний центр
    paint.color = AppTheme.success.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.95), size.width * 0.16, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

