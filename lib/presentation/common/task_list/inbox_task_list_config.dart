import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/inbox_drag_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/task.dart';
import '../../inbox/widgets/inbox_task_tile.dart';
import 'task_list_config.dart';

/// Inbox 页面的任务列表配置
class InboxTaskListConfig implements TaskListConfig {
  @override
  ProviderBase get dragProvider => inboxDragProvider;

  @override
  ProviderBase getExpandedProvider(WidgetRef ref) {
    return inboxExpandedTaskIdProvider;
  }

  @override
  ProviderBase getLevelMapProvider(WidgetRef ref) {
    return inboxTaskLevelMapProvider;
  }

  @override
  ProviderBase getChildrenMapProvider(WidgetRef ref) {
    return inboxTaskChildrenMapProvider;
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
    return InboxTaskTile(
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
    final allInboxTasks = await taskRepository.watchInbox().first;
    await sortIndexService.reorderTasksForInbox(tasks: allInboxTasks);
  }

  @override
  DateTime? handleDueDate({
    required TaskSection? section,
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    // Inbox 不需要处理 section，返回 null（保持原 dueDate）
    return null;
  }

  @override
  String? handleMilestoneId({
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  }) {
    // Inbox 页面不需要处理里程碑
    return null;
  }

  @override
  TaskSection? get section => null;

  @override
  String get pageName => 'Inbox';

  @override
  dynamic getDragNotifier(WidgetRef ref) {
    return ref.read(inboxDragProvider.notifier);
  }
}

