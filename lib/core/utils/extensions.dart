import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
}

extension DateTimeX on DateTime {
  String toShortDateTime() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(day)}.${two(month)}.$year ${two(hour)}:${two(minute)}';
  }

  String toHmAm() => DateFormat('h:mm a').format(this);

  String toRelativeTime({DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(this);
    if (diff.isNegative) return 'just now';

    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    return DateFormat('d MMM').format(this);
  }
}

