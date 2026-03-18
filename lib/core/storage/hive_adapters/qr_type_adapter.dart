import 'package:hive/hive.dart';

import '../../../shared/models/qr_type.dart';

class QrTypeAdapter extends TypeAdapter<QrType> {
  @override
  final int typeId = 0;

  @override
  QrType read(BinaryReader reader) {
    final index = reader.readByte();
    if (index < 0 || index >= QrType.values.length) return QrType.unknown;
    return QrType.values[index];
  }

  @override
  void write(BinaryWriter writer, QrType obj) {
    writer.writeByte(obj.index);
  }
}

