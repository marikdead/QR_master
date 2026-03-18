import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_storage.dart';

class OnboardingRepository {
  OnboardingRepository(this._storage);

  final LocalStorage _storage;

  bool getOnboardingShown() {
    return _storage.getBool(AppConstants.keyOnboardingShown, defaultValue: false);
  }

  Future<void> setOnboardingShown() async {
    await _storage.setBool(AppConstants.keyOnboardingShown, true);
  }
}

