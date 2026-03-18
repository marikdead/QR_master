import 'package:equatable/equatable.dart';

import '../../../shared/models/qr_type.dart';

class HistoryItem with EquatableMixin {
  HistoryItem({
    required this.id,
    required this.type,
    required this.content,
    required this.title,
    required this.scannedAt,
  });

  final String id;

  final QrType type;

  final String content;

  final String title;

  final DateTime scannedAt;

  @override
  List<Object?> get props => [id, type, content, title, scannedAt];
}

