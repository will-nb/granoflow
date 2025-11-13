import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/tasks_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../widgets/simplified_task_row.dart';
import '../../common/task_list/task_list_config.dart';

/// 里程碑任务列表配置
///
/// 用于项目详情页的拖拽逻辑，支持跨里程碑拖拽
class MilestoneTaskListConfig implements TaskListConfig {
  MilestoneTaskListConfig(this._milestoneId);

  final String _milestoneId;

  @override
  ProviderBase get dragProvider => tasksDragProvider;

  @override
  ProviderBase getExpandedProvider(WidgetRef ref) {
    return milestoneExpandedTaskIdProvider(_milestoneId);
  }

  @override
  ProviderBase getLevelMapProvider(WidgetRef ref) {
    // 层级功能已移除，返回空的 Provider
    return FutureProvider<Map<String, int>>((ref) async => <String, int>{});
  }

  @override
  ProviderBase getChildrenMapProvider(WidgetRef ref) {
    // 层级功能已移除，返回空的 Provider
    return FutureProvider<Map<String, Set<String>>>((ref) async => <String, Set<String>>{});
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
    // 使用 SimplifiedTaskRow（通过 TasksSectionTaskListSimplified 间接使用）
    // 注意：这里需要传入 section，但里程碑不是基于 section 的，所以传入 null
    // SimplifiedTaskRow 应该能够处理 section 为 null 的情况
    return SimplifiedTaskRow(
      key: key,
      task: task,
      section: null, // 里程碑不是基于 section 的
      showCheckbox: true,
      verticalPadding: contentPadding?.resolve(TextDirection.ltr).vertical ?? 8.0,
    );
  }

  @override
  Future<void> reorderTasks({
    required WidgetRef ref,
    required List<Task> allTasks,
    DateTime? targetDate,
  }) async {
    debugPrint('[MilestoneTaskListConfig] reorderTasks called: allTasksCount=${allTasks.length}, milestoneId=$_milestoneId');
    try {
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final sortIndexService = await ref.read(sortIndexServiceProvider.future);
      debugPrint('[MilestoneTaskListConfig] reorderTasks: repositories obtained');

      final allTasksList = await taskRepository.listAll();
      debugPrint('[MilestoneTaskListConfig] reorderTasks: listAll returned ${allTasksList.length} tasks');

      debugPrint('[MilestoneTaskListConfig] reorderTasks: calling reorderTasksForSameMilestone with allTasksCount=${allTasksList.length}, milestoneId=$_milestoneId');
      await sortIndexService.reorderTasksForSameMilestone(
        allTasks: allTasksList,
        targetMilestoneId: _milestoneId,
      );
      debugPrint('[MilestoneTaskListConfig] reorderTasks: reorderTasksForSameMilestone completed successfully');
    } catch (error, stackTrace) {
      debugPrint('[MilestoneTaskListConfig] reorderTasks: ERROR - $error');
      debugPrint('[MilestoneTaskListConfig] reorderTasks: StackTrace - $stackTrace');
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
    // 里程碑拖拽不需要处理 dueDate
    return null;
  }

  @override
  String? handleMilestoneId({
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    debugPrint('[MilestoneTaskListConfig] handleMilestoneId called: milestoneId=$_milestoneId, draggedTask=${draggedTask.id}, draggedTask.milestoneId=${draggedTask.milestoneId}');
    debugPrint('[MilestoneTaskListConfig] handleMilestoneId: beforeTask=${beforeTask?.id}, beforeTask.milestoneId=${beforeTask?.milestoneId}');
    debugPrint('[MilestoneTaskListConfig] handleMilestoneId: afterTask=${afterTask?.id}, afterTask.milestoneId=${afterTask?.milestoneId}');

    // 检测目标任务的 milestoneId
    // 优先使用 beforeTask，如果没有则使用 afterTask
    final targetTask = beforeTask ?? afterTask;
    if (targetTask == null) {
      // 如果两个任务都不存在，使用当前配置的里程碑ID
      if (draggedTask.milestoneId != _milestoneId) {
        debugPrint('[MilestoneTaskListConfig] handleMilestoneId: no target task, using config milestoneId=$_milestoneId');
        return _milestoneId;
      }
      return null;
    }

    final targetMilestoneId = targetTask.milestoneId;
    if (targetMilestoneId == null || targetMilestoneId.isEmpty) {
      // 目标任务没有里程碑，不更新
      debugPrint('[MilestoneTaskListConfig] handleMilestoneId: target task has no milestoneId, returning null');
      return null;
    }

    // 如果目标任务的 milestoneId 与拖拽任务不同，返回目标里程碑ID
    if (targetMilestoneId != draggedTask.milestoneId) {
      debugPrint('[MilestoneTaskListConfig] handleMilestoneId: cross-milestone drag detected, returning targetMilestoneId=$targetMilestoneId');
      return targetMilestoneId;
    }

    debugPrint('[MilestoneTaskListConfig] handleMilestoneId: same milestone, returning null');
    return null;
  }

  @override
  TaskSection? get section => null;

  @override
  String get pageName => 'ProjectDetail';

  @override
  dynamic getDragNotifier(WidgetRef ref) {
    return ref.read(tasksDragProvider.notifier);
  }
}

