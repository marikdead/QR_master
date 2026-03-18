import 'package:flutter/material.dart';

import '../../../history/domain/history_item_model.dart';
import '../../../../shared/widgets/activity_tile.dart';

class RecentActivityTile extends StatelessWidget {
  const RecentActivityTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActivityTile(
      data: ActivityTileData(
        kind: _kindOf(item),
        type: item.type,
        content: item.content,
        occurredAt: item.scannedAt,
      ),
      onTap: onTap,
      variant: ActivityTileVariant.recent,
      showActions: false,
      showChevron: true,
    );
  }

  ActivityKind _kindOf(HistoryItem item) {
    final t = item.title.toLowerCase();
    if (t.startsWith('created') || t.contains('created ')) {
      return ActivityKind.created;
    }
    if (t.startsWith('shared') || t.contains('shared ')) {
      return ActivityKind.shared;
    }
    return ActivityKind.scanned;
  }
}
