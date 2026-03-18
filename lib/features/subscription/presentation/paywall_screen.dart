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

class _PaywallScreenState extends State<PaywallScreen> implements ApphudListener {
  static const Color _accent = Color(0xFF4DB6F5);
  static const Color _closeBg = Color(0xFFE8E8E8);
  static const Color _closeFg = Color(0xFF555555);

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
    Apphud.setListener(listener: this);
    _loadProducts();
  }

  @override
  void dispose() {
    Apphud.setListener(listener: null);
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final placement = await Apphud.placement('main_paywall');
      final products = placement?.paywall?.products ?? const <ApphudProduct>[];
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
          orElse: () =>
          _products.length > 1
              ? _products[math.min(1, _products.length - 1)]
              : _products.first,
        );
      case PaywallPlan.yearly:
        return _products.firstWhere(
              (p) =>
              match(p, const ['year', 'yearly', 'annual', '12mo', '12-mo']),
          orElse: () => _products.length > 2 ? _products[2] : _products.last,
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
    } catch (_) {
      // ignore
    }
    return price.toStringAsFixed(2);
  }

  String? _formattedPriceForPlan(PaywallPlan plan) {
    final product = _getProductForPlan(plan);
    if (product == null) return null;
    final price = _productPrice(product);
    final currencyCode = product.skProduct?.priceLocale.currencyCode;
    if (price == null) return null;
    return _formatPrice(price, currencyCode);
  }

  Future<void> _purchase(BuildContext context, PaywallPlan plan) async {
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

      // AppsFlyer purchase event (best-effort)
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
  Future<void> apphudDidChangeUserID(String userId) async {
    // no-op
  }

  @override
  Future<void> apphudDidFecthProducts(
      List<ApphudProductComposite> products) async {
    // no-op
  }

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {
    // no-op
  }

  @override
  Future<void> userDidLoad(ApphudUser user) async {
    // no-op
  }

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(
      List<ApphudNonRenewingPurchase> purchases) async {
    // no-op
  }

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {
    // no-op
  }

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {
    // no-op
  }

  Future<void> _openUrl(Uri url) async {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTile({
    required PaywallPlan plan,
    required String title,
    required String priceLine,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    String? trailingLine,
    String? struckThroughLine,
  }) {
    final isSelected = selectedPlan == plan;
    final borderColor = isSelected ? _accent : Colors.black.withValues(
        alpha: 0.14);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _busy
          ? null
          : () {
        setState(() => selectedPlan = plan);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                if (badgeText != null && badgeColor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              priceLine,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 12.5, color: Colors.black.withValues(alpha: 0.62)),
            ),
            if (struckThroughLine != null || trailingLine != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (struckThroughLine != null)
                    Text(
                      struckThroughLine,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (struckThroughLine != null &&
                      trailingLine != null) const SizedBox(width: 8),
                  if (trailingLine != null)
                    Text(
                      trailingLine,
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.70)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPrice = _formattedPriceForPlan(PaywallPlan.weekly);
    final monthlyPrice = _formattedPriceForPlan(PaywallPlan.monthly);
    final yearlyPrice = _formattedPriceForPlan(PaywallPlan.yearly);

    final yearlyProduct = _getProductForPlan(PaywallPlan.yearly);
    final yearlyPriceValue = yearlyProduct == null ? null : _productPrice(
        yearlyProduct);
    final yearlyCurrency = yearlyProduct?.skProduct?.priceLocale.currencyCode;

    final derivedOldYearlyPrice = yearlyPriceValue == null
        ? null
        : (yearlyPriceValue / 0.30);
    final derivedSavings = (yearlyPriceValue == null ||
        derivedOldYearlyPrice == null)
        ? null
        : (derivedOldYearlyPrice - yearlyPriceValue);

    return Scaffold(
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: _closeBg,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                                Icons.close, size: 18, color: _closeFg),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () =>
                              _restorePurchases(context),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: 'https://qrmaster.app',
                          foregroundColor: _accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(
                          'Unlock Full QR Tools',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Unlimited scans, custom QR creation, and full history access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5,
                              height: 1.35,
                              color: Color(0xFF5D5D5D)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _benefitCard(
                            icon: Icons.qr_code_scanner,
                            title: 'Unlimited QR Scans',
                            subtitle: 'Scan as many QR codes as you want',
                          );
                        case 1:
                          return _benefitCard(
                            icon: Icons.auto_awesome,
                            title: 'Create All QR Types',
                            subtitle: 'URL, Text, Contact, WiFi, and more',
                          );
                        case 2:
                          return _benefitCard(
                            icon: Icons.block,
                            title: 'No Ads',
                            subtitle: 'Clean, distraction-free experience',
                          );
                        case 3:
                          return _benefitCard(
                            icon: Icons.cloud_sync,
                            title: 'Cloud Backup',
                            subtitle: 'Sync across all your devices',
                          );
                        default:
                          return _benefitCard(
                            icon: Icons.analytics_outlined,
                            title: 'Advanced Analytics',
                            subtitle: 'Track scans and usage patterns',
                          );
                      }
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose your plan',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _planTile(
                          plan: PaywallPlan.weekly,
                          title: 'Weekly',
                          badgeText: 'MOST POPULAR',
                          badgeColor: _accent,
                          priceLine: '${weeklyPrice ?? '—'} / week',
                          subtitle: '3-day free trial',
                        ),
                        const SizedBox(height: 10),
                        _planTile(
                          plan: PaywallPlan.monthly,
                          title: 'Monthly',
                          priceLine: '${monthlyPrice ?? '—'} / month',
                          subtitle: 'Cancel anytime',
                        ),
                        const SizedBox(height: 10),
                        _planTile(
                          plan: PaywallPlan.yearly,
                          title: 'Yearly',
                          badgeText: 'SAVE 70%',
                          badgeColor: const Color(0xFF32B768),
                          priceLine: '${yearlyPrice ?? '—'} / year',
                          subtitle: 'Best value option',
                          struckThroughLine: derivedOldYearlyPrice == null
                              ? null
                              : _formatPrice(
                              derivedOldYearlyPrice, yearlyCurrency),
                          trailingLine: derivedSavings == null
                              ? null
                              : 'Save ${_formatPrice(
                              derivedSavings, yearlyCurrency)}',
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
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, -12),
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
                  onPressed: _busy ? null : () =>
                      _purchase(context, selectedPlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  child: Text(_busy ? 'Processing…' : 'Continue'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Auto-renewable. Cancel anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: Colors.black.withValues(alpha: 0.60)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () => _openUrl(_termsUrl),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Terms of Service', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.35)),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: () => _openUrl(_privacyUrl),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Privacy Policy', overflow: TextOverflow.ellipsis),
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
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.08), size.width * 0.38, paint);

    paint.color = const Color(0xFF4DB6F5).withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.12), size.width * 0.28, paint);

    paint.color = const Color(0xFF7ACBFF).withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.90), size.width * 0.40, paint);

    paint.color = const Color(0xFF7ACBFF).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.92), size.width * 0.24, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

