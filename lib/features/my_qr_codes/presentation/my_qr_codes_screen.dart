import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_code_scanner/app/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../../shared/models/qr_type.dart';
import '../data/my_qr_repository.dart';
import '../domain/saved_qr_model.dart';
import 'widgets/qr_card_grid.dart';
import 'widgets/qr_detail_sheet.dart';

class MyQrCodesScreen extends StatefulWidget {
  const MyQrCodesScreen({super.key});

  @override
  State<MyQrCodesScreen> createState() => _MyQrCodesScreenState();
}

class _MyQrCodesScreenState extends State<MyQrCodesScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  QrType? _filter;

  Future<void> _handleShare(SavedQrCode code) async {
    await Share.share(code.content);
  }

  void _handleEdit(SavedQrCode code) {
    context.push(AppConstants.routeCreateQr, extra: code);
  }

  Future<void> _handleDelete(SavedQrCode code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QR code?'),
        content: Text('«${code.name}» will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await injector<MyQrRepository>().delete(code.id);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = injector<MyQrRepository>();

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searching
              ? TextField(
            key: const ValueKey('searchField'),
            controller: _search,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          )
              : const Text(
            'My QR Codes',
            key: ValueKey('title'),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) _search.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FiltersRow(
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ValueListenableBuilder(
                  valueListenable:
                  Hive.box<SavedQrCode>(AppConstants.boxMyQrCodes).listenable(),
                  builder: (context, _, __) {
                    final items = repo.search(
                      query: _search.text,
                      filter: _filter,
                    );
                    if (items.isEmpty) {
                      return const _EmptyState();
                    }
                    return QrCardGrid(
                      items: items,
                      onTap: (code) async {
                        await repo.incrementViewCount(code.id);
                        final updated = repo.getById(code.id) ?? code;
                        await QrDetailSheet.show(context, updated);
                      },
                      onShare: _handleShare,
                      onEdit: _handleEdit,
                      onDelete: _handleDelete,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.selected,
    required this.onSelected,
  });

  final QrType? selected;
  final ValueChanged<QrType?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, QrType? value) {
      final bool isActive = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? null : Color(0xFFF6F7FA),
              gradient: isActive ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFFFFFFFF), // ← твой цвет
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            chip('All', null),
            chip('URL', QrType.url),
            chip('Text', QrType.text),
            chip('WiFi', QrType.wifi),
            chip('Contact', QrType.contact),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.qr_code_2, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 8),
          Text(
            'No QR codes yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to create your first QR code',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

