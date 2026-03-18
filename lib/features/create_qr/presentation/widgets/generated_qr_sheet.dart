import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class GeneratedQrSheet extends StatefulWidget {
  const GeneratedQrSheet({
    super.key,
    required this.data,
    required this.color,
    required this.onSaveToLibrary,
  });

  final String data;
  final Color color;
  final Future<void> Function(Uint8List pngBytes) onSaveToLibrary;

  static Future<void> show(
    BuildContext context, {
    required String data,
    required Color color,
    required Future<void> Function(Uint8List pngBytes) onSaveToLibrary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeneratedQrSheet(
        data: data,
        color: color,
        onSaveToLibrary: onSaveToLibrary,
      ),
    );
  }

  @override
  State<GeneratedQrSheet> createState() => _GeneratedQrSheetState();
}

class _GeneratedQrSheetState extends State<GeneratedQrSheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List> _renderPng() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderPng();
      final res = await ImageGallerySaverPlus.saveImage(bytes, quality: 100, name: 'qr_master');
      if (!mounted) return;
      final ok = (res['isSuccess'] == true) || (res['success'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Saved to gallery' : AppConstants.modalSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderPng();
      final dir = await getTemporaryDirectory();
      final file = XFile('${dir.path}/qr_master.png', mimeType: 'image/png', bytes: bytes);
      await Share.shareXFiles([file], text: 'QR Master');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToMyQr() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderPng();
      await widget.onSaveToLibrary(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.modalSaved)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.modalSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.border),
                ),
                child: QrImageView(
                  data: widget.data,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: widget.color),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: widget.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _saveToGallery,
                    icon: const Icon(Icons.download),
                    label: const Text('Save Image'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.ios_share),
                    label: const Text(AppConstants.modalShare),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _saveToMyQr,
                icon: const Icon(Icons.bookmark),
                label: const Text('Save to My QR Codes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

