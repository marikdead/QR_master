import 'package:hive/hive.dart';

import '../../../features/history/domain/history_item_model.dart';
import '../../../shared/models/qr_type.dart';

class HistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final int typeId = 1;

  @override
  HistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HistoryItem(
      id: fields[0] as String,
      type: (fields[1] as QrType?) ?? QrType.unknown,
      content: fields[2] as String,
      title: fields[3] as String,
      scannedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.scannedAt);
  }
}

