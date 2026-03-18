import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../models/qr_type.dart';

enum ActivityKind { scanned, created, shared }

class ActivityTileData {
  const ActivityTileData({
    required this.kind,
    required this.type,
    required this.content,
    required this.occurredAt,
  });

  final ActivityKind kind;
  final QrType type;
  final String content;
  final DateTime occurredAt;
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.data,
    required this.onTap,
    this.variant = ActivityTileVariant.history,
    this.showActions = true,
    this.showChevron = false,
  });

  final ActivityTileData data;
  final VoidCallback onTap;
  final ActivityTileVariant variant;
  final bool showActions;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(data.kind);
    final title = _displayTitle(data.type);
    final subtitle = _displaySubtitle(data.type, data.content);
    final meta = switch (variant) {
      ActivityTileVariant.history => '${visual.label} • ${data.occurredAt.toHmAm()}',
      ActivityTileVariant.recent => data.occurredAt.toRelativeTime(),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, showActions ? 12 : 16, 14),
          child: Row(
            children: [
              _leadingCircle(background: visual.background, icon: visual.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: 8),
                _circleAction(
                  tooltip: 'Copy',
                  icon: Icons.copy_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: data.content));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _circleAction(
                  tooltip: 'Share',
                  icon: Icons.ios_share_rounded,
                  onTap: () => Share.share(data.content),
                ),
              ] else if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _KindVisual _visualFor(ActivityKind kind) {
    return switch (kind) {
      ActivityKind.created => const _KindVisual(
          label: 'Created',
          background: Color(0xFF66C56F),
          icon: Icons.add,
        ),
      ActivityKind.shared => const _KindVisual(
          label: 'Shared',
          background: Color(0xFFFFB25A),
          icon: Icons.reply_rounded,
        ),
      ActivityKind.scanned => const _KindVisual(
          label: 'Scanned',
          background: Color(0xFF6EC6F5),
          icon: Icons.qr_code_2_rounded,
        ),
    };
  }

  String _displayTitle(QrType type) {
    return switch (type) {
      QrType.url => 'Website Link',
      QrType.wifi => 'WiFi Network',
      QrType.text => 'Text Message',
      QrType.contact => 'Contact Info',
      QrType.unknown => 'QR Code',
    };
  }

  String _displaySubtitle(QrType type, String raw) {
    final content = raw.trim();
    if (content.isEmpty) return '';
    return switch (type) {
      QrType.url => content,
      QrType.text => _oneLinePreview(content, max: 44),
      QrType.wifi => _tryParseWifiSsid(content) ?? _oneLinePreview(content, max: 44),
      QrType.contact => _tryParseVCardName(content) ?? _oneLinePreview(content, max: 44),
      QrType.unknown => _oneLinePreview(content, max: 44),
    };
  }

  String _oneLinePreview(String s, {required int max}) {
    final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= max) return oneLine;
    return '${oneLine.substring(0, max)}...';
  }

  String? _tryParseWifiSsid(String s) {
    final m = RegExp(r'(?:^|;)S:([^;]*)(?:;|$)').firstMatch(s);
    final ssid = m?.group(1)?.trim();
    if (ssid == null || ssid.isEmpty) return null;
    return ssid;
  }

  String? _tryParseVCardName(String s) {
    final m = RegExp(r'^FN:(.+)$', multiLine: true).firstMatch(s);
    final fn = m?.group(1)?.trim();
    if (fn == null || fn.isEmpty) return null;
    return fn;
  }

  Widget _leadingCircle({
    required Color background,
    required IconData icon,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _circleAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: const Color(0xFFF3F5F8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

enum ActivityTileVariant { history, recent }

class _KindVisual {
  const _KindVisual({
    required this.label,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color background;
  final IconData icon;
}

