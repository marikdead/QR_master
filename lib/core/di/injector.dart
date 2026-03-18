import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/history/data/history_repository.dart';
import '../../features/history/domain/history_item_model.dart';
import '../../features/my_qr_codes/data/my_qr_repository.dart';
import '../../features/my_qr_codes/domain/saved_qr_model.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/scanner/data/scanner_repository.dart';
import '../../features/subscription/data/apphud_repository.dart';
import '../storage/local_storage.dart';
import '../constants/app_constants.dart';

final GetIt injector = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  injector.registerSingleton<LocalStorage>(LocalStorage(prefs));

  injector.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepository(injector<LocalStorage>()),
  );

  injector.registerLazySingleton<HistoryRepository>(
    () => HistoryRepository(Hive.box<HistoryItem>(AppConstants.boxHistory)),
  );

  injector.registerLazySingleton<MyQrRepository>(
    () => MyQrRepository(Hive.box<SavedQrCode>(AppConstants.boxMyQrCodes)),
  );

  injector.registerLazySingleton<ScannerRepository>(() => ScannerRepository());

  injector.registerLazySingleton<ApphudRepository>(() => ApphudRepository());
}

