import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';

class TaskHierarchyService {
  TaskHierarchyService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;

  Future<void> reorderWithinSection({
    required int taskId,
    required double targetIndex,
    required TaskSection section,
  }) async {
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: targetIndex,
    );
  }

  Future<void> moveToParent({
    required int taskId,
    required int? parentId,
    required double sortIndex,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) return;
    if (!task.canEditStructure) {
      throw StateError('Task is locked and cannot be moved.');
    }
    Task? parent;
    if (parentId != null) {
      parent = await _tasks.findById(parentId);
      if (parent == null) {
        throw StateError('Parent task $parentId not found.');
      }
      if (!parent.canEditStructure) {
        throw StateError('Parent task is locked; cannot add children.');
      }
    }
    await _tasks.updateTask(
      taskId,
      TaskUpdate(parentId: parentId, sortIndex: sortIndex),
    );
  }

  Future<void> moveAcrossSections({
    required int taskId,
    required TaskSection section,
    required double sortIndex,
    required DateTime dueDateLocal,
  }) async {
    final normalized = DateTime(
      dueDateLocal.year,
      dueDateLocal.month,
      dueDateLocal.day,
      23,
      59,
      59,
    );
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: sortIndex,
      dueAt: normalized,
    );
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}
