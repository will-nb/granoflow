import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/providers/tasks_drag_provider.dart';
import '../../../../core/utils/task_section_utils.dart';
import '../../../../data/models/task.dart';
import '../../tasks/views/tasks_section_task_tile.dart';
import 'task_list_config.dart';

/// Tasks Section 页面的任务列表配置
class TasksSectionTaskListConfig implements TaskListConfig {
  TasksSectionTaskListConfig(this._section);

  final TaskSection _section;

  @override
  ProviderBase get dragProvider => tasksDragProvider;

  @override
  ProviderBase getExpandedProvider(WidgetRef ref) {
    return tasksSectionExpandedTaskIdProvider(_section);
  }

  @override
  ProviderBase getLevelMapProvider(WidgetRef ref) {
    return tasksSectionTaskLevelMapProvider(_section);
  }

  @override
  ProviderBase getChildrenMapProvider(WidgetRef ref) {
    return tasksSectionTaskChildrenMapProvider(_section);
  }

  @override
  Widget buildTaskTile({
    required Task task,
    required Key key,
    EdgeInsetsGeometry? contentPadding,
    Widget? trailing,
    VoidCallback? onDragStarted,
    void Function(DragUpdateDetails)? onDragUpdate,
    VoidCallback? onDragEnd,
    double? childWhenDraggingOpacity,
    int? taskLevel,
  }) {
    return TasksSectionTaskTile(
      key: key,
      task: task,
      contentPadding: contentPadding,
      trailing: trailing,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      childWhenDraggingOpacity: childWhenDraggingOpacity,
      taskLevel: taskLevel,
    );
  }

  @override
  Future<void> reorderTasks({
    required WidgetRef ref,
    required List<Task> allTasks,
    DateTime? targetDate,
  }) async {
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final sortIndexService = await ref.read(sortIndexServiceProvider.future);
    final allTasksList = await taskRepository.listAll();
    await sortIndexService.reorderTasksForSameDate(
      allTasks: allTasksList,
      targetDate: targetDate,
    );
  }

  @override
  DateTime? handleDueDate({
    required TaskSection? section,
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    // Tasks 页面需要处理 section 和跨区域拖拽
    final now = DateTime.now();
    
    // 优先使用 beforeTask 或 afterTask 的 dueAt 来确定目标区域
    DateTime? targetDueDate = beforeTask?.dueAt ?? afterTask?.dueAt ?? draggedTask.dueAt;
    
    // 计算目标 section
    final targetSection = TaskSectionUtils.getSectionForDate(targetDueDate, now: now);
    final currentSection = TaskSectionUtils.getSectionForDate(draggedTask.dueAt, now: now);
    
    // 如果是跨区域拖拽，需要使用目标区域的结束时间
    final isCrossSectionByParam = _section != currentSection;
    final isCrossSectionByTarget = targetSection != currentSection;
    
    if (isCrossSectionByParam || isCrossSectionByTarget) {
      // 跨区域拖拽：使用目标区域的结束时间
      // 优先使用参数传入的 section，因为它更准确（来自插入目标的 widget.section）
      final finalTargetSection = isCrossSectionByParam ? _section : targetSection;
      return TaskSectionUtils.getSectionEndTime(finalTargetSection, now: now);
    }
    
    // 同区域拖拽，返回原 dueDate 或目标任务的 dueAt
    return targetDueDate;
  }

  @override
  TaskSection? get section => _section;

  @override
  String get pageName => 'Tasks';

  @override
  dynamic getDragNotifier(WidgetRef ref) {
    return ref.read(tasksDragProvider.notifier);
  }
}

