import 'dart:async';

import '../../data/models/metric_snapshot.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/metric_repository.dart';
import '../../data/repositories/task_repository.dart';

enum MetricRecomputeReason { task, session, seedImport }

class MetricOrchestrator {
  MetricOrchestrator({
    required MetricRepository metricRepository,
    required TaskRepository taskRepository,
    required FocusSessionRepository focusRepository,
  }) : _metricRepository = metricRepository,
       _taskRepository = taskRepository,
       _focusRepository = focusRepository;

  final MetricRepository _metricRepository;
  final TaskRepository _taskRepository;
  final FocusSessionRepository _focusRepository;

  final _debounce = _Debouncer();

  Stream<MetricSnapshot?> latest() => _metricRepository.watchLatest();

  Future<MetricSnapshot> requestRecompute(MetricRecomputeReason reason) async {
    return _debounce.run(() async {
      final tasks = await _taskRepository.listAll();
      final totalFocusMinutes = await _focusRepository.totalMinutesOverall();
      final snapshot = await _metricRepository.recompute(
        tasks: tasks,
        totalFocusMinutes: totalFocusMinutes,
      );
      return snapshot;
    });
  }

  Future<void> invalidate() => _metricRepository.invalidate();
}

class _Debouncer {
  Timer? _timer;
  Completer<MetricSnapshot>? _pending;

  Future<MetricSnapshot> run(Future<MetricSnapshot> Function() action) {
    _timer?.cancel();
    _pending ??= Completer<MetricSnapshot>();
    _timer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final result = await action();
        _pending?.complete(result);
      } catch (err, stack) {
        _pending?.completeError(err, stack);
      } finally {
        _pending = null;
      }
    });
    return _pending!.future;
  }
}
