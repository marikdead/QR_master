import '../../../shared/models/qr_type.dart';

class ScanParsedResult {
  const ScanParsedResult({
    required this.type,
    required this.content,
    required this.title,
    this.url,
    this.wifiSsid,
    this.wifiPassword,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
  });

  final QrType type;
  final String content;
  final String title;

  final String? url;

  final String? wifiSsid;
  final String? wifiPassword;

  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
}

