import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import 'interstitial_counter.dart';

class AdNavigationObserver extends NavigatorObserver {
  // Экраны на которых межстраничная НЕ показывается
  static const _excludedRoutes = <String>[
    AppConstants.routeSplash,
    AppConstants.routeOnboarding,
    AppConstants.routePaywall,
  ];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    final name = route.settings.name ?? '';
    final isExcluded = _excludedRoutes.contains(name);
    if (!isExcluded) {
      InterstitialCounter().onNavigate();
    }
  }
}

