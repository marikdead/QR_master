import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/qr_type.dart';

class SavedQrCode with EquatableMixin {
  SavedQrCode({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.colorValue,
    required this.createdAt,
    this.qrImagePath,
    this.viewCount = 0,
  });

  final String id;
  final String name;
  final QrType type;
  final String content;
  final int colorValue;
  final DateTime createdAt;
  final String? qrImagePath;
  final int viewCount;

  SavedQrCode copyWith({
    String? id,
    String? name,
    QrType? type,
    String? content,
    int? colorValue,
    DateTime? createdAt,
    String? qrImagePath,
    int? viewCount,
  }) {
    return SavedQrCode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      qrImagePath: qrImagePath ?? this.qrImagePath,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  List<Object?> get props => [id, name, type, content, colorValue, createdAt, qrImagePath, viewCount];
}

extension SavedQrCodeUI on SavedQrCode {
  String get subtitle {
    final v = content.trim();
    return v.length > 30 ? '${v.substring(0, 30)}...' : v;
  }

  String get formattedDate => DateFormat('MMM d, yyyy').format(createdAt);
}

