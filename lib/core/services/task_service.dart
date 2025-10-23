import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import 'metric_orchestrator.dart';

class TaskService {
  TaskService({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    required MetricOrchestrator metricOrchestrator,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _tags = tagRepository,
       _metricOrchestrator = metricOrchestrator,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final TagRepository _tags;
  final MetricOrchestrator _metricOrchestrator;
  final DateTime Function() _clock;

  Future<Task> captureInboxTask({
    required String title,
    List<String> tags = const <String>[],
  }) async {
    final draft = TaskDraft(
      title: title,
      status: TaskStatus.inbox,
      tags: tags,
      allowInstantComplete: false,
      sortIndex: _clock().millisecondsSinceEpoch.toDouble(),
    );
    final task = await _tasks.createTask(draft);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return task;
  }

  Future<void> planTask({
    required int taskId,
    required DateTime dueDateLocal,
    required TaskSection section,
  }) async {
    final normalizedDue = _normalizeDueDate(dueDateLocal);
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: _clock().millisecondsSinceEpoch.toDouble(),
      dueAt: normalizedDue,
    );
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) async {
    await _tasks.updateTask(taskId, payload);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> updateTags({
    required int taskId,
    String? contextTag,
    String? priorityTag,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      return;
    }
    final normalized = task.tags
        .where((tag) => !_isContextTag(tag) && !_isPriorityTag(tag))
        .toList(growable: true);
    if (contextTag != null && contextTag.isNotEmpty) {
      normalized.add(contextTag);
    }
    if (priorityTag != null && priorityTag.isNotEmpty) {
      normalized.add(priorityTag);
    }
    await _tasks.updateTask(taskId, TaskUpdate(tags: normalized));
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> markInProgress(int taskId) async {
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.doing);
  }

  Future<void> markCompleted({
    required int taskId,
    bool autoCompleteParent = true,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      return;
    }
    if (!task.canEditStructure && !task.allowInstantComplete) {
      throw StateError('Task is locked and cannot be completed directly.');
    }
    await _tasks.updateTask(
      taskId,
      TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
    );
    if (autoCompleteParent && task.parentId != null) {
      final siblings = await _tasks.listChildren(task.parentId!);
      final allCompleted = siblings.every(
        (sibling) => sibling.status == TaskStatus.completedActive,
      );
      if (allCompleted) {
        await _tasks.updateTask(
          task.parentId!,
          TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> archive(int taskId) async {
    await _tasks.archiveTask(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> softDelete(int taskId) async {
    final task = await _tasks.findById(taskId);
    if (task != null && task.templateLockCount > 0) {
      throw StateError('Task is locked by templates; remove template first.');
    }
    await _tasks.softDelete(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<List<Tag>> listTagsByKind(TagKind kind) => _tags.listByKind(kind);

  Future<List<Task>> searchTasksByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) {
      return Future.value(const <Task>[]);
    }
    return _tasks.searchByTitle(
      query,
      status: status,
      limit: limit,
    );
  }

  DateTime _normalizeDueDate(DateTime localDate) {
    final converted = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
    return converted;
  }

  bool _isContextTag(String tag) => tag.startsWith('@');
  bool _isPriorityTag(String tag) => tag.startsWith('#');
}
