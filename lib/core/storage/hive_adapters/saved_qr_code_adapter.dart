import 'package:hive/hive.dart';

import '../../../features/my_qr_codes/domain/saved_qr_model.dart';
import '../../../shared/models/qr_type.dart';

class SavedQrCodeAdapter extends TypeAdapter<SavedQrCode> {
  @override
  final int typeId = 2;

  @override
  SavedQrCode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SavedQrCode(
      id: fields[0] as String,
      name: fields[1] as String,
      type: (fields[2] as QrType?) ?? QrType.unknown,
      content: fields[3] as String,
      colorValue: fields[4] as int,
      createdAt: fields[5] as DateTime,
      qrImagePath: fields[6] as String?,
      viewCount: (fields[7] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SavedQrCode obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.qrImagePath)
      ..writeByte(7)
      ..write(obj.viewCount);
  }
}

