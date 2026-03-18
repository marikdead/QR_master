import 'package:go_router/go_router.dart';

import '../../core/ads/ad_navigation_observer.dart';
import '../../core/constants/app_constants.dart';
import '../main_shell.dart';
import '../../features/create_qr/presentation/create_qr_screen.dart';
import '../../features/create_qr/domain/generated_qr_model.dart';
import '../../features/create_qr/presentation/generated_qr_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/scanner/domain/scan_result_model.dart';
import '../../features/scanner/presentation/scan_result_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../features/my_qr_codes/presentation/my_qr_codes_screen.dart';
import '../../features/my_qr_codes/domain/saved_qr_model.dart';

class AppRouter {
  static GoRouter create() => GoRouter(
        initialLocation: AppConstants.routeSplash,
        observers: [AdNavigationObserver()],
        routes: [
          GoRoute(
            path: AppConstants.routeSplash,
            name: AppConstants.routeSplash,
            builder: (_, __) => const SplashScreen(),
          ),
          GoRoute(
            path: AppConstants.routeOnboarding,
            name: AppConstants.routeOnboarding,
            builder: (_, __) => const OnboardingScreen(),
          ),
          ShellRoute(
            builder: (_, __, child) => MainShell(child: child),
            routes: [
              GoRoute(
                path: AppConstants.routeHome,
                name: AppConstants.routeHome,
                builder: (_, __) => const HomeScreen(),
              ),
              GoRoute(
                path: AppConstants.routeScanner,
                name: AppConstants.routeScanner,
                builder: (_, __) => const ScannerScreen(),
              ),
              GoRoute(
                path: AppConstants.routeScanResult,
                name: AppConstants.routeScanResult,
                builder: (context, state) {
                  final result = state.extra as ScanResultModel;
                  return ScanResultScreen(result: result);
                },
              ),
              GoRoute(
                path: AppConstants.routeMyQrCodes,
                name: AppConstants.routeMyQrCodes,
                builder: (_, __) => const MyQrCodesScreen(),
              ),
              GoRoute(
                path: AppConstants.routeHistory,
                name: AppConstants.routeHistory,
                builder: (_, __) => const HistoryScreen(),
              ),
              GoRoute(
                path: AppConstants.routeCreateQr,
                name: AppConstants.routeCreateQr,
                builder: (context, state) {
                  final initial = state.extra is SavedQrCode ? state.extra as SavedQrCode : null;
                  return CreateQrScreen(initial: initial);
                },
              ),
              GoRoute(
                path: AppConstants.routeGeneratedQr,
                name: AppConstants.routeGeneratedQr,
                builder: (context, state) {
                  final model = state.extra as GeneratedQrModel;
                  return GeneratedQrScreen(model: model);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppConstants.routePaywall,
            name: AppConstants.routePaywall,
            builder: (_, __) => const PaywallScreen(),
          ),
        ],
      );
}

