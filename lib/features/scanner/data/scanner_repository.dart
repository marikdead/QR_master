import '../../../shared/models/qr_type.dart';
import '../domain/scan_parsed_result.dart';

class ScannerRepository {
  ScanParsedResult parse(String raw) {
    final content = raw.trim();

    final url = _tryParseUrl(content);
    if (url != null) {
      return ScanParsedResult(
        type: QrType.url,
        content: content,
        title: url,
        url: url,
      );
    }

    final wifi = _tryParseWifi(content);
    if (wifi != null) return wifi;

    final contact = _tryParseContact(content);
    if (contact != null) return contact;

    return ScanParsedResult(
      type: QrType.text,
      content: content,
      title: _shorten(content),
    );
  }

  String? _tryParseUrl(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(s);
    } catch (_) {
      return null;
    }

    if (!uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  ScanParsedResult? _tryParseWifi(String input) {
    // Common format: WIFI:T:WPA;S:MySSID;P:mypass;;
    final s = input.trim();
    if (!s.toUpperCase().startsWith('WIFI:')) return null;

    final body = s.substring(5);
    final parts = body.split(';');
    String? ssid;
    String? pass;
    for (final p in parts) {
      if (p.startsWith('S:')) ssid = p.substring(2);
      if (p.startsWith('P:')) pass = p.substring(2);
    }
    if (ssid == null || ssid.trim().isEmpty) return null;

    return ScanParsedResult(
      type: QrType.wifi,
      content: s,
      title: ssid.trim(),
      wifiSsid: ssid.trim(),
      wifiPassword: pass,
    );
  }

  ScanParsedResult? _tryParseContact(String input) {
    final s = input.trim();
    if (s.toUpperCase().startsWith('MECARD:')) {
      final body = s.substring(7);
      final parts = body.split(';');
      String? name;
      String? phone;
      String? email;
      for (final p in parts) {
        if (p.startsWith('N:')) name = p.substring(2);
        if (p.startsWith('TEL:')) phone = p.substring(4);
        if (p.startsWith('EMAIL:')) email = p.substring(6);
      }
      final title = (name?.trim().isNotEmpty ?? false)
          ? name!.trim()
          : (phone?.trim().isNotEmpty ?? false)
              ? phone!.trim()
              : 'Contact';
      return ScanParsedResult(
        type: QrType.contact,
        content: s,
        title: title,
        contactName: name?.trim().isEmpty ?? true ? null : name!.trim(),
        contactPhone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
        contactEmail: email?.trim().isEmpty ?? true ? null : email!.trim(),
      );
    }

    if (s.toUpperCase().contains('BEGIN:VCARD')) {
      // Keep lightweight: try to extract FN / TEL / EMAIL.
      final lines = s.split(RegExp(r'\r?\n'));
      String? fn;
      String? tel;
      String? email;
      for (final line in lines) {
        final upper = line.toUpperCase();
        if (upper.startsWith('FN:')) fn = line.substring(3).trim();
        if (upper.startsWith('TEL:')) tel = line.substring(4).trim();
        if (upper.startsWith('EMAIL:')) email = line.substring(6).trim();
      }
      if (fn == null && tel == null && email == null) return null;
      return ScanParsedResult(
        type: QrType.contact,
        content: s,
        title: fn ?? tel ?? email ?? 'Contact',
        contactName: fn,
        contactPhone: tel,
        contactEmail: email,
      );
    }

    return null;
  }

  String _shorten(String s) {
    final v = s.trim();
    if (v.length <= 32) return v;
    return '${v.substring(0, 32)}…';
  }
}

