import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injector.dart';
import '../../data/my_qr_repository.dart';
import '../../domain/saved_qr_model.dart';

class QrDetailSheet {
  static Future<void> show(BuildContext context, SavedQrCode code) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(code: code),
    );
  }
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.code});

  final SavedQrCode code;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List> _renderPng() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderPng();
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/qr_master_share.png');
      await f.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(f.path)], text: widget.code.name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final bytes = await _renderPng();
      await ImageGallerySaverPlus.saveImage(bytes, quality: 100, name: 'qr_master');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await injector<MyQrRepository>().delete(widget.code.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Color(widget.code.colorValue);

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
            Text(widget.code.name, style: Theme.of(context).textTheme.headlineMedium),
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
                  data: widget.code.content,
                  version: QrVersions.auto,
                  size: 240,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: c),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: c,
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
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

