import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/appsflyer_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../data/scanner_repository.dart';
import '../domain/scan_result_model.dart';
import 'widgets/scan_frame_overlay.dart';
import 'widgets/scanner_controls.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _handling = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureCameraPermission());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handling = true;
    try {
      final parsed = injector<ScannerRepository>().parse(raw);

      // Analytics
      await injector<AppsFlyerService>().logEvent(AppsFlyerService.eventScanQr);

      if (!mounted) return;
      final result = ScanResultModel(
        type: parsed.type,
        fullContent: parsed.content,
        scannedAt: DateTime.now(),
      );

      // Останавливаем сканер, чтобы не словить повторные детекты/переходы.
      await _controller.stop();
      await context.push(AppConstants.routeScanResult, extra: result);

      if (!mounted) return;
      await _controller.start();
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _handling = false;
    }
  }

  Future<void> _toggleFlash() async {
    await _controller.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
  }

  Future<void> _fromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final res = await _controller.analyzeImage(file.path);
    if (!mounted) return;
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found in image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 76,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5AC8FA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // выравнивание по центру
                          children: [
                            Text(
                              'Align QR code within frame',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Keep your device steady',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48,),
              Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                        ),
                        const ScanFrameOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48,),
              ScannerControls(
                flashEnabled: _flashOn,
                onFlash: _toggleFlash,
                onSwitchCamera: _switchCamera,
                onGallery: _fromGallery,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

