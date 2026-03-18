import 'ad_service.dart';

class InterstitialCounter {
  static final InterstitialCounter _instance = InterstitialCounter._internal();
  factory InterstitialCounter() => _instance;
  InterstitialCounter._internal();

  int _navigationCount = 0;
  static const int _showEveryN = 4; // показывать каждый 4-й переход

  void onNavigate() {
    _navigationCount++;
    if (_navigationCount % _showEveryN == 0) {
      AdService().showInterstitialIfReady();
    }
  }
}

