import 'package:flutter/foundation.dart';

@immutable
class MetricSnapshot {
  const MetricSnapshot({
    required this.id,
    required this.totalCompletedTasks,
    required this.totalFocusMinutes,
    required this.pendingTasks,
    required this.pendingTodayTasks,
    required this.calculatedAt,
  });

  final String id;
  final int totalCompletedTasks;
  final int totalFocusMinutes;
  final int pendingTasks;
  final int pendingTodayTasks;
  final DateTime calculatedAt;
}
