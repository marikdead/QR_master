import '../../../shared/models/qr_type.dart';

class ScanResultModel {
  const ScanResultModel({
    required this.type,
    required this.fullContent,
    required this.scannedAt,
  });

  final QrType type;
  final String fullContent;
  final DateTime scannedAt;

  String get typeLabel => switch (type) {
        QrType.url => 'Website URL',
        QrType.text => 'Plain Text',
        QrType.contact => 'Contact',
        QrType.wifi => 'Wi‑Fi Network',
        QrType.unknown => 'Unknown',
      };

  String get shortValue {
    final v = fullContent.trim();
    if (v.length <= 40) return v;
    return '${v.substring(0, 40)}...';
  }

  String get scannedTimeLabel {
    final diff = DateTime.now().difference(scannedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    return '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
  }
}

