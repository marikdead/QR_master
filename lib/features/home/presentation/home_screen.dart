import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/history_item_model.dart';
import '../../scanner/domain/scan_result_model.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/recent_activity_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRepo = injector<HistoryRepository>();

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '${AppConstants.homeWelcome}!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.homeSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: [
                QuickActionCard(
                  title: AppConstants.actionScanQr,
                  subtitle: AppConstants.descScanQr,
                  icon: SvgPicture.asset('assets/svg/homescreen/scan_qr_icon.svg'),
                  iconBackground: AppColors.primary,
                  onTap: () => context.go(AppConstants.routeScanner),
                ),
                QuickActionCard(
                  title: AppConstants.actionCreateQr,
                  subtitle: AppConstants.descCreateQr,
                  icon: SvgPicture.asset('assets/svg/homescreen/plus.svg'),
                  iconBackground: AppTheme.success,
                  onTap: () => context.push(AppConstants.routeCreateQr),
                ),
                QuickActionCard(
                  title: AppConstants.actionMyQrCodes,
                  subtitle: AppConstants.descMyQR,
                  icon: SvgPicture.asset('assets/svg/homescreen/saved_codes_folder_icon.svg'),
                  iconBackground: AppTheme.warning,
                  onTap: () => context.go(AppConstants.routeMyQrCodes),
                ),
                QuickActionCard(
                  title: AppConstants.actionHistory,
                  subtitle: AppConstants.descHistory,
                  icon: SvgPicture.asset('assets/svg/homescreen/history_icon.svg'),
                  iconBackground: AppTheme.neutral,
                  onTap: () => context.go(AppConstants.routeHistory),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              AppConstants.homeRecentActivity,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: Hive.box<HistoryItem>(AppConstants.boxHistory).listenable(),
              builder: (context, _, __) {
                final recent = historyRepo.getRecent(limit: 5);
                if (recent.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      AppConstants.homeNoRecentActivity,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final item in recent) ...[
                      RecentActivityTile(
                        item: item,
                        onTap: () => context.push(
                          AppConstants.routeScanResult,
                          extra: ScanResultModel(
                            type: item.type,
                            fullContent: item.content,
                            scannedAt: item.scannedAt,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

