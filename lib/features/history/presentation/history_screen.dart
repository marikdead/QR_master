import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../data/history_repository.dart';
import '../domain/history_item_model.dart';
import '../../scanner/domain/scan_result_model.dart';
import 'widgets/history_tile.dart';

enum _HistoryFilter { all, scanned, created }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final repo = injector<HistoryRepository>();

    Future<void> clearAll() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Clear history?'),
            content: const Text('This will delete all history items.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          );
        },
      );
      if (ok == true) await repo.clear();
    }

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<HistoryItem>(AppConstants.boxHistory).listenable(),
          builder: (context, _, __) {
            final all = repo.getAll();
            final items = _applyFilterAndSort(all);

            return CustomScrollView(
              slivers: [
                // Шапка — без боковых отступов
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.primaryBg,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'History',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _circleHeaderAction(
                              icon: Icons.swap_vert_rounded,
                              onTap: () async {
                                final action = await showModalBottomSheet<String>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.swap_vert_rounded),
                                              title: Text(_newestFirst ? 'Sort: newest first' : 'Sort: oldest first'),
                                              subtitle: const Text('Tap to toggle'),
                                              onTap: () => Navigator.pop(context, 'toggle_sort'),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                              title: const Text('Clear history', style: TextStyle(color: Colors.red)),
                                              onTap: () => Navigator.pop(context, 'clear'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                if (!mounted) return;
                                if (action == 'toggle_sort') {
                                  setState(() => _newestFirst = !_newestFirst);
                                } else if (action == 'clear') {
                                  await clearAll();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _filterChip(
                              label: 'All',
                              selected: _filter == _HistoryFilter.all,
                              onTap: () => setState(() => _filter = _HistoryFilter.all),
                            ),
                            const SizedBox(width: 10),
                            _filterChip(
                              label: 'Scanned',
                              selected: _filter == _HistoryFilter.scanned,
                              onTap: () => setState(() => _filter = _HistoryFilter.scanned),
                            ),
                            const SizedBox(width: 10),
                            _filterChip(
                              label: 'Created',
                              selected: _filter == _HistoryFilter.created,
                              onTap: () => setState(() => _filter = _HistoryFilter.created),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Список — со своими отступами
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  sliver: items.isEmpty
                      ? SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'No history yet',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildListDelegate(
                      _buildSectionedList(context, items, repo),
                    ),
                  ),
                ),
              ],
            );          },
        ),
      ),
    );
  }

  List<HistoryItem> _applyFilterAndSort(List<HistoryItem> all) {
    Iterable<HistoryItem> filtered = all;
    if (_filter == _HistoryFilter.scanned) {
      filtered = filtered.where((e) => _kindOf(e) == _HistoryFilter.scanned);
    } else if (_filter == _HistoryFilter.created) {
      filtered = filtered.where((e) => _kindOf(e) == _HistoryFilter.created);
    }

    final out = filtered.toList(growable: false)
      ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));

    return _newestFirst ? out.reversed.toList(growable: false) : out;
  }

  _HistoryFilter _kindOf(HistoryItem item) {
    final t = item.title.toLowerCase();
    if (t.startsWith('created') || t.contains('created ')) return _HistoryFilter.created;
    return _HistoryFilter.scanned;
  }

  List<Widget> _buildSectionedList(BuildContext context, List<HistoryItem> items, HistoryRepository repo) {
    final now = DateTime.now();
    final groups = <String, List<HistoryItem>>{};
    final order = <String>[];

    for (final it in items) {
      final key = _dayKey(now, it.scannedAt);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(it);
    }

    final children = <Widget>[];
    for (final key in order) {
      children.addAll([
        const SizedBox(height: 10),
        Text(
          key,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
      ]);

      final sectionItems = groups[key]!;
      for (var i = 0; i < sectionItems.length; i++) {
        final item = sectionItems[i];
        children.add(
          Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            onDismissed: (_) => repo.delete(item.id),
            child: HistoryTile(
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
          ),
        );
        if (i != sectionItems.length - 1) {
          children.add(const SizedBox(height: 12));
        }
      }
    }

    return children;
  }

  String _dayKey(DateTime now, DateTime dt) {
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);
    final diff = d0.difference(d1).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fg = selected ? Colors.white : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? AppColors.primaryGradient
              : null,
          color: selected ? null : Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _circleHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: const Color(0xFFF3F5F8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

