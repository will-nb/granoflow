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
    debugPrint('[TasksSectionTaskListConfig] reorderTasks called: allTasksCount=${allTasks.length}, targetDate=$targetDate, section=$_section');
    try {
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final sortIndexService = await ref.read(sortIndexServiceProvider.future);
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: repositories obtained');
      
      final allTasksList = await taskRepository.listAll();
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: listAll returned ${allTasksList.length} tasks');
      
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: calling reorderTasksForSameDate with allTasksCount=${allTasksList.length}, targetDate=$targetDate');
      await sortIndexService.reorderTasksForSameDate(
        allTasks: allTasksList,
        targetDate: targetDate,
      );
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: reorderTasksForSameDate completed successfully');
    } catch (error, stackTrace) {
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: ERROR - $error');
      debugPrint('[TasksSectionTaskListConfig] reorderTasks: StackTrace - $stackTrace');
      rethrow;
    }
  }

  @override
  DateTime? handleDueDate({
    required TaskSection? section,
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    debugPrint('[TasksSectionTaskListConfig] handleDueDate called: section=$section, _section=$_section, draggedTask=${draggedTask.id}, draggedTask.dueAt=${draggedTask.dueAt}');
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: beforeTask=${beforeTask?.id}, beforeTask.dueAt=${beforeTask?.dueAt}');
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: afterTask=${afterTask?.id}, afterTask.dueAt=${afterTask?.dueAt}');
    
    // Tasks 页面需要处理 section 和跨区域拖拽
    final now = DateTime.now();
    
    // 优先使用 beforeTask 或 afterTask 的 dueAt 来确定目标区域
    DateTime? targetDueDate = beforeTask?.dueAt ?? afterTask?.dueAt ?? draggedTask.dueAt;
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: targetDueDate=$targetDueDate (from beforeTask: ${beforeTask?.dueAt}, afterTask: ${afterTask?.dueAt}, draggedTask: ${draggedTask.dueAt})');
    
    // 计算目标 section
    final targetSection = TaskSectionUtils.getSectionForDate(targetDueDate, now: now);
    final currentSection = TaskSectionUtils.getSectionForDate(draggedTask.dueAt, now: now);
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: targetSection=$targetSection, currentSection=$currentSection');
    
    // 如果是跨区域拖拽，需要使用目标区域的结束时间
    final isCrossSectionByParam = _section != currentSection;
    final isCrossSectionByTarget = targetSection != currentSection;
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: isCrossSectionByParam=$isCrossSectionByParam, isCrossSectionByTarget=$isCrossSectionByTarget');
    
    if (isCrossSectionByParam || isCrossSectionByTarget) {
      // 跨区域拖拽：使用目标区域的结束时间
      // 优先使用参数传入的 section，因为它更准确（来自插入目标的 widget.section）
      final finalTargetSection = isCrossSectionByParam ? _section : targetSection;
      final sectionEndTime = TaskSectionUtils.getSectionEndTime(finalTargetSection, now: now);
      debugPrint('[TasksSectionTaskListConfig] handleDueDate: cross-section drag, returning sectionEndTime=$sectionEndTime for section=$finalTargetSection');
      return sectionEndTime;
    }
    
    // 同区域拖拽，返回原 dueDate 或目标任务的 dueAt
    debugPrint('[TasksSectionTaskListConfig] handleDueDate: same-section drag, returning targetDueDate=$targetDueDate');
    return targetDueDate;
  }

  @override
  String? handleMilestoneId({
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    // Tasks 页面不需要处理里程碑
    return null;
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

