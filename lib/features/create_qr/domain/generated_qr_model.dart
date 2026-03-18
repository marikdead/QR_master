import 'package:flutter/material.dart';

import '../../../shared/models/qr_type.dart';

class GeneratedQrModel {
  const GeneratedQrModel({
    required this.content,
    required this.type,
    required this.color,
    required this.createdAt,
  });

  final String content;
  final QrType type;
  final Color color;
  final DateTime createdAt;
}

