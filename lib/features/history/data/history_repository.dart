import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/history_item_model.dart';

class HistoryRepository {
  HistoryRepository(this._box);

  final Box<HistoryItem> _box;

  List<HistoryItem> getAll() {
    final items = _box.values.toList(growable: false);
    items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  List<HistoryItem> getRecent({int limit = 5}) {
    final all = getAll();
    return all.take(limit).toList(growable: false);
  }

  Future<void> add(HistoryItem item) async {
    await _box.put(item.id, item);
    await _enforceLimit();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> _enforceLimit() async {
    final max = AppConstants.historyMaxItems;
    if (_box.length <= max) return;

    final items = _box.values.toList(growable: false)
      ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt)); // oldest first

    final overflow = items.length - max;
    for (var i = 0; i < overflow; i++) {
      await _box.delete(items[i].id);
    }
  }
}

