import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';
import 'sort_index_service.dart';
import 'task_crud_service_helpers.dart';
import 'task_crud_service_update.dart';

/// 任务 CRUD 操作服务
/// 负责任务的创建、读取、更新和删除操作
class TaskCrudService {
  TaskCrudService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    SortIndexService? sortIndexService,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndex = sortIndexService,
       _helpers = TaskCrudServiceHelpers(taskRepository: taskRepository),
       _update = TaskCrudServiceUpdate(
         taskRepository: taskRepository,
         metricOrchestrator: metricOrchestrator,
         helpers: TaskCrudServiceHelpers(taskRepository: taskRepository),
         clock: clock,
       );

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexService? _sortIndex;
  final TaskCrudServiceHelpers _helpers;
  final TaskCrudServiceUpdate _update;

  /// 递归获取所有后代任务（包括子任务的子任务）
  ///
  /// [taskId] 起始任务 ID
  /// 返回所有后代任务的列表（排除 project 和 milestone）
  Future<List<Task>> getAllDescendantTasks(int taskId) =>
      _helpers.getAllDescendantTasks(taskId);

  /// 在 Inbox 中创建任务
  Future<Task> captureInboxTask({
    required String title,
    List<String> tags = const <String>[],
  }) async {
    final draft = TaskDraft(
      title: title,
      status: TaskStatus.inbox,
      tags: tags,
      allowInstantComplete: false,
      sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
    );
    final task = await _tasks.createTask(draft);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return task;
  }

  /// 规划任务（设置截止日期和区域）
  Future<void> planTask({
    required int taskId,
    required DateTime dueDateLocal,
    required TaskSection section,
  }) async {
    final normalizedDue = TaskCrudServiceHelpers.normalizeDueDate(dueDateLocal);
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
      dueAt: normalizedDue,
    );
    // 规则：新任务插入到本区域最前
    try {
      final tasksInSection = await _tasks.listSectionTasks(section);
      // 找到当前首个"其它任务"（排除自己）
      final firstOther = tasksInSection.firstWhere(
        (t) => t.id != taskId,
        orElse: () => Task(
          id: -1,
          taskId: '',
          title: '',
          status: TaskStatus.pending,
          createdAt: DateTime(1970, 1, 1),
          updatedAt: DateTime(1970, 1, 1),
          sortIndex: 0,
        ),
      );
      if (firstOther.id == -1) {
        // 区域为空或只有自己 → 赋默认HEAD
        await _tasks.updateTask(taskId, const TaskUpdate(sortIndex: 1024));
      } else {
        final sortIndex = _sortIndex;
        if (sortIndex != null) {
          await sortIndex.moveToHead(
            draggedId: taskId,
            section: section,
            firstId: firstOther.id,
          );
        } else {
          // 退化实现：直接写 head = first.sortIndex - STEP
          final newIndex = (firstOther.sortIndex - 1024).toDouble();
          await _tasks.updateTask(taskId, TaskUpdate(sortIndex: newIndex));
        }
      }
    } catch (_) {
      // 忽略排序错误，保证主流程
    }

    // 如果任务有子任务，同步更新所有子任务的截止日期和状态
    // 子任务的状态会通过 batchUpdate 中的状态转换逻辑自动变为 pending
    final allChildren = await _helpers.getAllDescendantTasks(taskId);
    if (allChildren.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[TaskCrudService.planTask] 同步子任务截止日期: taskId=$taskId, childrenCount=${allChildren.length}, newDueAt=$normalizedDue, section=$section',
        );
      }
      final updates = <int, TaskUpdate>{};
      for (final child in allChildren) {
        updates[child.id] = TaskUpdate(dueAt: normalizedDue);
      }
      await _tasks.batchUpdate(updates);
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 更新任务详情
  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) =>
      _update.updateDetails(taskId: taskId, payload: payload);

  /// 更新任务标签
  Future<void> updateTags({
    required int taskId,
    String? contextTag,
    String? priorityTag,
  }) =>
      _update.updateTags(taskId: taskId, contextTag: contextTag, priorityTag: priorityTag);

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearTrash() async {
    final count = await _tasks.clearAllTrashedTasks();
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return count;
  }
}
