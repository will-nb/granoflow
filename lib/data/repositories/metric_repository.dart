import 'dart:async';

import '../models/metric_snapshot.dart';
import '../models/task.dart';

abstract class MetricRepository {
  Future<MetricSnapshot> recompute({
    required Iterable<Task> tasks,
    required int totalFocusMinutes,
  });

  Stream<MetricSnapshot?> watchLatest();

  Future<void> invalidate();
}

class InMemoryMetricRepository implements MetricRepository {
  MetricSnapshot? _latest;
  final StreamController<MetricSnapshot?> _controller =
      StreamController<MetricSnapshot?>.broadcast();
  int _nextId = 1;

  @override
  Future<MetricSnapshot> recompute({
    required Iterable<Task> tasks,
    required int totalFocusMinutes,
  }) async {
    final totalCompleted = tasks
        .where((task) => task.status == TaskStatus.completedActive)
        .length;
    final pendingTasks = tasks
        .where((task) => task.status == TaskStatus.pending)
        .length;
    final now = DateTime.now();
    final pendingToday = tasks.where((task) {
      if (task.status != TaskStatus.pending) {
        return false;
      }
      final due = task.dueAt;
      return due != null &&
          due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).length;
    _latest = MetricSnapshot(
      id: _nextId++,
      totalCompletedTasks: totalCompleted,
      totalFocusMinutes: totalFocusMinutes,
      pendingTasks: pendingTasks,
      pendingTodayTasks: pendingToday,
      calculatedAt: now,
    );
    _controller.add(_latest);
    return _latest!;
  }

  @override
  Stream<MetricSnapshot?> watchLatest() =>
      _controller.stream.startWith(_latest);

  @override
  Future<void> invalidate() async {
    _latest = null;
    _controller.add(_latest);
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
