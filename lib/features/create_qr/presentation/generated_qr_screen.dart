import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../../shared/models/qr_type.dart';
import '../../../shared/widgets/header.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/history_item_model.dart';
import '../../my_qr_codes/data/my_qr_repository.dart';
import '../../my_qr_codes/domain/saved_qr_model.dart';
import '../domain/generated_qr_model.dart';

class GeneratedQrScreen extends StatefulWidget {
  const GeneratedQrScreen({super.key, required this.model});

  final GeneratedQrModel model;

  @override
  State<GeneratedQrScreen> createState() => _GeneratedQrScreenState();
}

class _GeneratedQrScreenState extends State<GeneratedQrScreen> {
  final _qrKey = GlobalKey();
  bool _busy = false;
  bool _isSaved = false;
  late final String _savedQrId;
  late final String _historyId;

  @override
  void initState() {
    super.initState();
    final uuid = const Uuid();
    _savedQrId = uuid.v4();
    _historyId = uuid.v4();

    // По макету созданные коды должны сразу появляться в My QR и History.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSaved(auto: true);
    });
  }

  Future<Uint8List> _renderPng() async {
    final boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _shareQr() async {
    setState(() => _busy = true);
    try {
      final pngBytes = await _renderPng();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png')
        ..writeAsBytesSync(pngBytes);
      await Share.shareXFiles([XFile(file.path)]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ensureSaved({required bool auto}) async {
    if (_isSaved) return;

    setState(() => _busy = true);
    try {
      final repo = injector<MyQrRepository>();
      final savedQr = SavedQrCode(
        id: _savedQrId,
        name: _generateName(widget.model),
        type: widget.model.type,
        content: widget.model.content,
        colorValue: widget.model.color.value,
        createdAt: widget.model.createdAt,
        qrImagePath: null,
      );
      await repo.save(savedQr);

      final historyRepo = injector<HistoryRepository>();
      await historyRepo.add(
        HistoryItem(
          id: _historyId,
          type: widget.model.type,
          content: widget.model.content,
          title: 'Created ${widget.model.type.label} QR',
          scannedAt: widget.model.createdAt,
        ),
      );

      if (!mounted) return;
      setState(() => _isSaved = true);
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.modalSaved)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.modalSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _generateName(GeneratedQrModel model) {
    switch (model.type) {
      case QrType.url:
        return Uri.tryParse(model.content)?.host ?? model.content;
      case QrType.text:
        final t = model.content.trim();
        return t.length > 20 ? '${t.substring(0, 20)}...' : t;
      case QrType.contact:
        final fn = RegExp(r'FN:(.+)').firstMatch(model.content);
        return fn?.group(1)?.trim() ?? 'Contact';
      case QrType.wifi:
        final s = RegExp(r'S:([^;]+)').firstMatch(model.content);
        return s?.group(1) ?? 'Wi‑Fi';
      case QrType.unknown:
        return 'QR Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Create QR Code',
              onClose: () => context.go(AppConstants.routeHome),
            ),
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _SuccessBadge(),
                    const SizedBox(height: 24),
                    RepaintBoundary(key: _qrKey, child: _QrContainer(model: widget.model)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            svgPath: 'assets/svg/shared/share_icon.svg',
                            label: 'Share',
                            onTap: _busy ? null : _shareQr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            svgPath: _isSaved
                                ? 'assets/svg/shared/save_icon.svg'
                                : 'assets/svg/shared/save_icon.svg',
                            label: 'Save',
                            onTap: _busy ? null : () => _ensureSaved(auto: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.check, color: Colors.white, size: 36),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'The QR code is ready',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _QrContainer extends StatelessWidget {
  const _QrContainer({required this.model});

  final GeneratedQrModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4DB6F5), width: 1.5),
      ),
      child: Column(
        children: [
          QrImageView(
            data: model.content,
            version: QrVersions.auto,
            size: 220,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: model.color,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: model.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFE0E0E0)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.svgPath,
    required this.label,
    required this.onTap,
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                svgPath,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Color(0xFF555555), BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
