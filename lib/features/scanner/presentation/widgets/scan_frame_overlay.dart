import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

// scan_frame_geometry.dart
class ScanFrameGeometry {
  static const double widthFraction = 0.82;
  static const double heightFraction = 0.62;

  static Rect computeFrame(Size size) {
    final frameW = size.width * widthFraction;
    final frameH = size.height * heightFraction;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    return Rect.fromLTWH(left, top, frameW, frameH);
  }
}

class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({super.key});

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ScanOverlayPainter(lineT: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({required this.lineT});

  final double lineT;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(AppTheme.radiusXL),
    );

    // Frame border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(frame, borderPaint);

    // Corners
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const corner = 26.0;
    final r = frame.outerRect;

    // top-left
    canvas.drawLine(Offset(r.left, r.top + corner), Offset(r.left, r.top), cornerPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + corner, r.top), cornerPaint);
    // top-right
    canvas.drawLine(Offset(r.right - corner, r.top), Offset(r.right, r.top), cornerPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + corner), cornerPaint);
    // bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - corner), Offset(r.left, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + corner, r.bottom), cornerPaint);
    // bottom-right
    canvas.drawLine(Offset(r.right - corner, r.bottom), Offset(r.right, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.right, r.bottom - corner), Offset(r.right, r.bottom), cornerPaint);

    // Scanning line
    final y = r.top + (r.height * (0.15 + 0.7 * lineT));
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.primary.withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(r.left, y - 1, r.width, 2))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(r.left + 12, y), Offset(r.right - 12, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) => oldDelegate.lineT != lineT;
}

