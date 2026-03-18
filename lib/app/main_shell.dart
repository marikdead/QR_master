import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';

import '../core/constants/app_constants.dart';
import '../shared/widgets/ad_banner_widget.dart';
import '../shared/widgets/app_fab.dart';
import '../shared/widgets/app_tab_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = <String>[
    AppConstants.routeHome,
    AppConstants.routeScanner,
    AppConstants.routeMyQrCodes,
    AppConstants.routeHistory,
  ];

  int _locationToIndex(String location) {
    if (location.startsWith(AppConstants.routeCreateQr) ||
        location.startsWith(AppConstants.routeGeneratedQr)) {
      return -1;
    }
    if (location.startsWith(AppConstants.routeScanner) ||
        location.startsWith(AppConstants.routeScanResult)) {
      return 1;
    }
    final idx = _tabs.indexWhere((p) => location.startsWith(p));
    return idx == -1 ? 0 : idx;
  }

  bool _shouldShowBanner(String location) {
    return !location.startsWith(AppConstants.routeSplash) &&
        !location.startsWith(AppConstants.routeOnboarding) &&
        !location.startsWith(AppConstants.routePaywall);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: SafeArea(child: child),

      floatingActionButton: AppFab(
        onPressed: () {
          if (location.startsWith(AppConstants.routeCreateQr)) return;
          context.push(AppConstants.routeCreateQr);
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: AppColors.primaryBg,
            notchMargin: 8,
            child: AppTabBar(
              currentIndex: currentIndex,
              onTap: (index) => context.go(_tabs[index]),
            ),
          ),
          if (_shouldShowBanner(location)) const AdBannerWidget(),
        ],
      ),
    );
  }
}