import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/ads/ad_service.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injector.dart';
import 'core/storage/hive_adapters/history_item_adapter.dart';
import 'core/storage/hive_adapters/qr_type_adapter.dart';
import 'core/storage/hive_adapters/saved_qr_code_adapter.dart';
import 'features/history/domain/history_item_model.dart';
import 'features/my_qr_codes/domain/saved_qr_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(QrTypeAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HistoryItemAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SavedQrCodeAdapter());

  await Hive.openBox<HistoryItem>(AppConstants.boxHistory);
  await Hive.openBox<SavedQrCode>(AppConstants.boxMyQrCodes);
  await Hive.openBox(AppConstants.boxSettings);

  await configureDependencies();

  // AdMob — до runApp
  await AdService().initialize();

  runApp(const App());
}
