import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AppsFlyerService {
  AppsFlyerService(this._sdk);

  final AppsflyerSdk _sdk;

  static const String eventScanQr = 'af_scan_qr';
  static const String eventCreateQr = 'af_create_qr';
  static const String eventSubscriptionStarted = 'af_subscription_started';

  Future<void> init() async {
    await _sdk.initSdk(
      registerConversionDataCallback: true,
    );
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? values}) async {
    await _sdk.logEvent(name, values ?? <String, dynamic>{});
  }
}

