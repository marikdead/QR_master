import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/shared/widgets/header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../../app/theme/app_components.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../../shared/models/qr_type.dart';
import '../../../shared/widgets/success_badge.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/history_item_model.dart';
import '../data/scanner_repository.dart';
import '../domain/scan_parsed_result.dart';
import '../domain/scan_result_model.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.result});

  final ScanResultModel result;

  String _primaryLabel(ScanParsedResult parsed) {
    return switch (parsed.type) {
      QrType.url     => 'Open Link',
      QrType.contact => 'Add to Contacts',
      QrType.wifi    => 'Connect to Wi-Fi',
      QrType.text || QrType.unknown => 'Copy Text',
    };
  }

  @override
  Widget build(BuildContext context) {
    final parsed = injector<ScannerRepository>().parse(result.fullContent);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Scan Result',
              onClose: () => context.go(AppConstants.routeHome),
            ),
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    const SuccessBadge(),
                    const SizedBox(height: 16),
                    _CombinedCard(parsed: parsed, result: result),
                    const SizedBox(height: 24),
                    PrimaryGradientButton(
                      label: _primaryLabel(parsed),
                      onPressed: () => _openContent(context, parsed, result),
                    ),
                    const SizedBox(height: 16),
                    _SecondaryActions(
                      onCopy: () => _copy(context, result.fullContent),
                      onSave: () => _saveToHistory(context, parsed, result),
                      onShare: () => _share(result.fullContent),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openContent(BuildContext context, ScanParsedResult parsed, ScanResultModel result) async {
    switch (parsed.type) {
      case QrType.url:
        final url = parsed.url ?? result.fullContent;
        final uri = Uri.tryParse(url);
        if (uri == null) {
          _snack(context, 'Invalid URL');
          return;
        }
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) _snack(context, 'Unable to open link');
        return;
      case QrType.contact:
        await _addToContacts(context, parsed);
        return;
      case QrType.wifi:
        await _connectWifi(context, parsed);
        return;
      case QrType.text:
      case QrType.unknown:
        await _copy(context, result.fullContent);
        return;
    }
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    _snack(context, 'Copied to clipboard');
  }

  Future<void> _share(String text) async {
    await Share.share(text);
  }

  Future<void> _saveToHistory(BuildContext context, ScanParsedResult parsed, ScanResultModel result) async {
    try {
      final repo = injector<HistoryRepository>();
      final item = HistoryItem(
        id: const Uuid().v4(),
        type: parsed.type,
        content: result.fullContent,
        title: parsed.title,
        scannedAt: result.scannedAt,
      );
      await repo.add(item);
      if (!context.mounted) return;
      _snack(context, 'Saved to history');
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, 'Unable to save');
    }
  }

  Future<void> _addToContacts(BuildContext context, ScanParsedResult parsed) async {
    try {
      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        if (!context.mounted) return;
        _snack(context, 'Нет доступа к контактам (разрешение не выдано)');
        return;
      }

      final contact = Contact();
      if (parsed.contactName != null) {
        contact.name.first = parsed.contactName!;
      }
      if (parsed.contactPhone != null) {
        contact.phones = [Phone(parsed.contactPhone!)];
      }
      if (parsed.contactEmail != null) {
        contact.emails = [Email(parsed.contactEmail!)];
      }
      await contact.insert();
      if (!context.mounted) return;
      _snack(context, 'Contact saved');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Не удалось сохранить контакт');
    }
  }

  Future<void> _connectWifi(BuildContext context, ScanParsedResult parsed) async {
    final ssid = parsed.wifiSsid;
    if (ssid == null || ssid.isEmpty) return;
    try {
      if (context.mounted) _snack(context, 'Connecting to WiFi...');
      await WiFiForIoTPlugin.connect(
        ssid,
        password: parsed.wifiPassword,
        joinOnce: true,
      );
    } catch (_) {
      // no-op
    }
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _CombinedCard extends StatelessWidget {
  const _CombinedCard({required this.parsed, required this.result});

  final ScanParsedResult parsed;
  final ScanResultModel result;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconColor, typeLabel) = _typeVisuals(parsed.type, result.typeLabel);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Text(
                      result.shortValue,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFF0F0F0)),

          // Full Content block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full Content',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.fullContent,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: Color(0xFFF0F0F0)),

          // Meta row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanned',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  Text(
                    result.scannedTimeLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Type',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  Text(
                    result.type.name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color, String) _typeVisuals(QrType type, String fallbackLabel) {
    return switch (type) {
      QrType.url    => (Icons.link,       const Color(0xFFE8F4FD), const Color(0xFF4DB6F5), 'Website URL'),
      QrType.text   => (Icons.text_fields, const Color(0xFFE8F4FD), const Color(0xFF4DB6F5), 'Plain Text'),
      QrType.contact => (Icons.person,    const Color(0xFFE8F4FD), const Color(0xFF4DB6F5), 'Contact'),
      QrType.wifi   => (Icons.wifi,       const Color(0xFFE8F4FD), const Color(0xFF4DB6F5), 'Wi‑Fi Network'),
      QrType.unknown => (Icons.qr_code_2, const Color(0xFFE8F4FD), const Color(0xFF4DB6F5), fallbackLabel),
    };
  }
}

class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({required this.onCopy, required this.onSave, required this.onShare});

  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionIcon(svgPath: 'assets/svg/shared/copy_icon.svg', label: 'Copy', onTap: onCopy)),
        const SizedBox(width: 12),
        Expanded(child: _ActionIcon(svgPath: 'assets/svg/shared/share_icon.svg', label: 'Share', onTap: onShare)),
        const SizedBox(width: 12),
        Expanded(child: _ActionIcon(svgPath: 'assets/svg/shared/save_icon.svg', label: 'Save', onTap: onSave)),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.svgPath, required this.label, required this.onTap});

  final String svgPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                svgPath,
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(Color(0xFF444444), BlendMode.srcIn),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

