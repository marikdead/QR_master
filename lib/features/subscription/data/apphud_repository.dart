import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';

class ApphudRepository {
  Future<void> start({required String apiKey}) async {
    await Apphud.start(apiKey: apiKey);
  }

  Future<bool> hasPremiumAccess() async {
    return Apphud.hasPremiumAccess();
  }

  Future<ApphudPaywalls> paywalls() async {
    return Apphud.paywallsDidLoadCallback();
  }

  Future<ApphudPurchaseResult> purchase(ApphudProduct product) async {
    return Apphud.purchase(product: product);
  }

  Future<void> restorePurchases() async {
    await Apphud.restorePurchases();
  }
}

