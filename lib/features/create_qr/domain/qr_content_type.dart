enum QrContentType {
  url,
  text,
  contact,
  wifi,
}

extension QrContentTypeX on QrContentType {
  String get label => switch (this) {
        QrContentType.url => 'URL',
        QrContentType.text => 'Text',
        QrContentType.contact => 'Contact',
        QrContentType.wifi => 'Wi‑Fi',
      };
}

