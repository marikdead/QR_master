enum QrType {
  url,
  text,
  contact,
  wifi,
  unknown,
}

extension QrTypeX on QrType {
  String get label => switch (this) {
        QrType.url => 'URL',
        QrType.text => 'Text',
        QrType.contact => 'Contact',
        QrType.wifi => 'WiFi',
        QrType.unknown => 'Unknown',
      };
}

