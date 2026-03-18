import 'dart:math' as math;

import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/apphud_non_renewing_purchase.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/appsflyer_service.dart';
import '../../../core/di/injector.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum PaywallPlan { weekly, monthly, yearly }

class _PaywallScreenState extends State<PaywallScreen>
    implements ApphudListener {
  static const bool _useApphud = false;
  static const Color _accent = Color(0xFF4DB6F5);
  static const Color _closeBg = Color(0xFFE8E8E8);
  static const Color _closeFg = Color(0xFF555555);
  static const Color _green = Color(0xFF32B768);

  static final Uri _termsUrl = Uri.parse('https://qrmaster.app/terms');
  static final Uri _privacyUrl = Uri.parse('https://qrmaster.app/privacy');

  PaywallPlan selectedPlan = PaywallPlan.monthly;

  List<ApphudProduct> _products = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_useApphud) {
      Apphud.setListener(listener: this);
      _loadProducts();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    if (_useApphud) {
      Apphud.setListener(listener: null);
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!_useApphud) return;
    try {
      final placement = await Apphud.placement('main_paywall');
      final products =
          placement?.paywall?.products ?? const <ApphudProduct>[];
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  ApphudProduct? _getProductForPlan(PaywallPlan plan) {
    if (_products.isEmpty) return null;
    bool match(ApphudProduct p, List<String> needles) {
      final id = (p.productId).toLowerCase();
      final name = (p.name ?? '').toLowerCase();
      return needles.any((n) => id.contains(n) || name.contains(n));
    }

    switch (plan) {
      case PaywallPlan.weekly:
        return _products.firstWhere(
              (p) => match(p, const ['week', 'weekly', '7day', '7-day']),
          orElse: () => _products.first,
        );
      case PaywallPlan.monthly:
        return _products.firstWhere(
              (p) =>
              match(p, const ['month', 'monthly', '1mo', '30day', '30-day']),
          orElse: () => _products.length > 1
              ? _products[math.min(1, _products.length - 1)]
              : _products.first,
        );
      case PaywallPlan.yearly:
        return _products.firstWhere(
              (p) =>
              match(p, const ['year', 'yearly', 'annual', '12mo', '12-mo']),
          orElse: () =>
          _products.length > 2 ? _products[2] : _products.last,
        );
    }
  }

  double? _productPrice(ApphudProduct product) {
    final price = product.skProduct?.price;
    return (price is num) ? price?.toDouble() : null;
  }

  String _formatPrice(double price, String? currencyCode) {
    try {
      if (currencyCode != null && currencyCode.isNotEmpty) {
        return NumberFormat.simpleCurrency(name: currencyCode).format(price);
      }
    } catch (_) {}
    return price.toStringAsFixed(2);
  }

  String? _formattedPriceForPlan(PaywallPlan plan) {
    if (!_useApphud) {
      switch (plan) {
        case PaywallPlan.weekly:
          return '\$3.99';
        case PaywallPlan.monthly:
          return '\$7.99';
        case PaywallPlan.yearly:
          return '\$29.99';
      }
    }
    final product = _getProductForPlan(plan);
    if (product == null) return null;
    final price = _productPrice(product);
    final currencyCode = product.skProduct?.priceLocale.currencyCode;
    if (price == null) return null;
    return _formatPrice(price, currencyCode);
  }

  Future<void> _purchase(BuildContext context, PaywallPlan plan) async {
    if (!_useApphud) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock purchase completed')),
        );
        context.pop();
      }
      return;
    }
    final product = _getProductForPlan(plan);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Products are still loading')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await Apphud.purchase(product: product);
      final price = _productPrice(product);
      final currency = product.skProduct?.priceLocale.currencyCode;
      await injector<AppsFlyerService>().logEvent('af_purchase', values: {
        'af_revenue': price,
        'af_currency': currency,
        'af_content_id': product.productId,
      });
      if (result.subscription?.isActive == true && context.mounted) {
        context.pop();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase completed')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    if (!_useApphud) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock restore: no purchases found')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await Apphud.restorePurchases();
      if (await Apphud.hasPremiumAccess()) {
        if (context.mounted) context.pop();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscriptions found')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Future<void> apphudSubscriptionsUpdated(
      List<ApphudSubscriptionWrapper> subscriptions) async {
    final isActive = subscriptions.any((s) => s.isActive);
    if (isActive && mounted) context.pop();
  }

  @override
  Future<void> apphudDidChangeUserID(String userId) async {}

  @override
  Future<void> apphudDidFecthProducts(
      List<ApphudProductComposite> products) async {}

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {}

  @override
  Future<void> userDidLoad(ApphudUser user) async {}

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(
      List<ApphudNonRenewingPurchase> purchases) async {}

  @override
  Future<void> placementsDidFullyLoad(
      List<ApphudPlacement> placements) async {}

  @override
  Future<void> apphudDidReceivePurchase(
      AndroidPurchaseWrapper purchase) async {}

  Future<void> _openUrl(Uri url) async {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Benefit card exactly as in screenshots: white card, blue circle icon, title+subtitle
  Widget _benefitCard({
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Plan card with badge ABOVE the card (not inside), matching screenshots
  Widget _planCard({
    required PaywallPlan plan,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    String? struckPrice,
    String? savingText,
  }) {
    final isSelected = selectedPlan == plan;

    final cardWidget = GestureDetector(
      onTap: _busy ? null : () => setState(() => selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badgeText != null) const SizedBox(height: 12), // отступ под бейдж
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $period',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (struckPrice != null && savingText != null) ...[
              Row(
                children: [
                  Text(
                    struckPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAAAAAA),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    savingText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );

    if (badgeText != null && badgeColor != null) {
      const badgeHeight = 26.0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: badgeHeight / 2),
            child: cardWidget,
          ),
          Positioned(
            top: 0,
            left: 18, // отступ от края карточки
            child: Container(
              height: badgeHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardWidget;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPrice = _formattedPriceForPlan(PaywallPlan.weekly) ?? '—';
    final monthlyPrice = _formattedPriceForPlan(PaywallPlan.monthly) ?? '—';
    final yearlyPrice = _formattedPriceForPlan(PaywallPlan.yearly) ?? '—';

    // Derived old/savings for yearly (hardcoded when not using Apphud)
    final String yearlyStruckPrice = _useApphud ? '\$99.99' : '\$99.99';
    final String yearlySaving = _useApphud ? 'Save \$70' : 'Save \$70';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _PaywallBackground(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : CustomScrollView(
              slivers: [
                // Top bar: close + restore
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: _closeBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 17,
                              color: _closeFg,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () =>
                              _restorePurchases(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Restore',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // QR code
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset('assets/svg/subscription_screen/qr.svg'), // <-- вставь сюда
                      ),
                    ),
                  ),
                ),

                // Title + subtitle
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(
                          'Unlock Full QR Tools',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Unlimited scans, custom QR creation, and full history access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Benefits list
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _benefitCard(
                            // Replace Icon with your SVG here:
                            icon: SvgPicture.asset('assets/svg/subscription_screen/unlimited.svg',
                                width: 22, height: 11,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            title: 'Unlimited QR Scans',
                            subtitle:
                            'Scan as many QR codes as you want',
                          );
                        case 1:
                          return _benefitCard(
                            icon: SvgPicture.asset('assets/svg/subscription_screen/all_types.svg',
                                width: 18, height: 18,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            // Replace Icon with your SVG here
                            title: 'Create All QR Types',
                            subtitle:
                            'URL, Text, Contact, WiFi, and more',
                          );
                        case 2:
                          return _benefitCard(
                            icon: SvgPicture.asset('assets/svg/subscription_screen/no_ads.svg',
                                width: 18, height: 18,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            // Replace Icon with your SVG here
                            title: 'No Ads',
                            subtitle:
                            'Clean, distraction-free experience',
                          );
                        case 3:
                          return _benefitCard(
                            icon: SvgPicture.asset('assets/svg/subscription_screen/cloud.svg',
                                width: 22, height: 15,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            // Replace Icon with your SVG here
                            title: 'Cloud Backup',
                            subtitle:
                            'Sync across all your devices',
                          );
                        default:
                          return _benefitCard(
                            icon: SvgPicture.asset('assets/svg/subscription_screen/analytics.svg',
                                width: 18, height: 15,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            // Replace Icon with your SVG here
                            title: 'Advanced Analytics',
                            subtitle:
                            'Track scans and usage patterns',
                          );
                      }
                    },
                  ),
                ),

                // Plans section
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 28, 20, 130),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _planCard(
                          plan: PaywallPlan.weekly,
                          title: 'Weekly Plan',
                          price: weeklyPrice,
                          period: 'week',
                          subtitle: '3-day free trial',
                          badgeText: 'MOST POPULAR',
                          badgeColor: _accent,
                        ),
                        const SizedBox(height: 12),
                        _planCard(
                          plan: PaywallPlan.monthly,
                          title: 'Monthly Plan',
                          price: monthlyPrice,
                          period: 'month',
                          subtitle: 'Cancel anytime',
                        ),
                        const SizedBox(height: 12),
                        _planCard(
                          plan: PaywallPlan.yearly,
                          title: 'Yearly Plan',
                          price: yearlyPrice,
                          period: 'year',
                          subtitle: 'Best value option',
                          badgeText: 'SAVE 70%',
                          badgeColor: _green,
                          struckPrice: yearlyStruckPrice,
                          savingText: yearlySaving,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                  _busy ? null : () => _purchase(context, selectedPlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    _accent.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child:
                  Text(_busy ? 'Processing…' : 'Continue'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Auto-renewable. Cancel anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openUrl(_termsUrl),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openUrl(_privacyUrl),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallBackground extends StatelessWidget {
  const _PaywallBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFDDF2FF),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _PaywallCirclesPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PaywallCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4DB6F5).withValues(alpha: 0.10);
    canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.08),
        size.width * 0.38,
        paint);

    paint.color = const Color(0xFF4DB6F5).withValues(alpha: 0.08);
    canvas.drawCircle(
        Offset(size.width * 0.95, size.height * 0.12),
        size.width * 0.28,
        paint);

    paint.color = const Color(0xFF7ACBFF).withValues(alpha: 0.08);
    canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.90),
        size.width * 0.40,
        paint);

    paint.color = const Color(0xFF7ACBFF).withValues(alpha: 0.06);
    canvas.drawCircle(
        Offset(size.width * 0.10, size.height * 0.92),
        size.width * 0.24,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}