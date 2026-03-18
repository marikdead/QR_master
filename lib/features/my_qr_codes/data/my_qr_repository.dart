import 'package:hive/hive.dart';

import '../domain/saved_qr_model.dart';
import '../../../shared/models/qr_type.dart';

class MyQrRepository {
  MyQrRepository(this._box);

  final Box<SavedQrCode> _box;

  List<SavedQrCode> getAll() {
    final items = _box.values.toList(growable: false);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  SavedQrCode? getById(String id) => _box.get(id);

  List<SavedQrCode> search({
    required String query,
    required QrType? filter,
  }) {
    final q = query.trim().toLowerCase();
    var items = getAll();

    if (filter != null) {
      items = items.where((e) => e.type == filter).toList(growable: false);
    }

    if (q.isEmpty) return items;

    return items
        .where((e) =>
            e.name.trim().toLowerCase().contains(q) ||
            e.content.trim().toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> save(SavedQrCode code) async {
    await _box.put(code.id, code);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> incrementViewCount(String id) async {
    final current = _box.get(id);
    if (current == null) return;
    final updated = current.copyWith(viewCount: current.viewCount + 1);
    await _box.put(id, updated);
  }
}

