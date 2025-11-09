import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task.dart';

/// 任务列表配置接口
///
/// 通过策略模式统一 Inbox 和 Tasks 页面的差异，包括：
/// - Provider 类型（Inbox 使用普通 Provider，Tasks 使用 family Provider）
/// - 任务卡片组件（InboxTaskTile vs TasksSectionTaskTile）
/// - 重排序方法（reorderTasksForInbox vs reorderTasksForSameDate）
/// - dueDate 处理（Tasks 需要 section，Inbox 不需要）
abstract class TaskListConfig {
  /// 获取拖拽状态 Provider
  ///
  /// Inbox: inboxDragProvider
  /// Tasks: tasksDragProvider
  ProviderBase get dragProvider;

  /// 获取展开状态 Provider
  ///
  /// Inbox: inboxExpandedTaskIdProvider (StateProvider<Set<String>>)
  /// Tasks: tasksSectionExpandedTaskIdProvider (StateProvider.family<Set<String>, TaskSection>)
  ProviderBase getExpandedProvider(WidgetRef ref);

  /// 获取层级映射 Provider
  ///
  /// Inbox: inboxTaskLevelMapProvider (FutureProvider<Map<String, int>>)
  /// Tasks: tasksSectionTaskLevelMapProvider (FutureProvider.family<Map<String, int>, TaskSection>)
  ProviderBase getLevelMapProvider(WidgetRef ref);

  /// 获取子任务映射 Provider
  ///
  /// Inbox: inboxTaskChildrenMapProvider (FutureProvider<Map<String, Set<String>>>)
  /// Tasks: tasksSectionTaskChildrenMapProvider (FutureProvider.family<Map<String, Set<String>>, TaskSection>)
  ProviderBase getChildrenMapProvider(WidgetRef ref);

  /// 构建任务卡片 Widget
  ///
  /// Inbox: InboxTaskTile
  /// Tasks: TasksSectionTaskTile
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
  });

  /// 执行重排序操作
  ///
  /// Inbox: reorderTasksForInbox
  /// Tasks: reorderTasksForSameDate（需要 targetDate）
  Future<void> reorderTasks({
    required WidgetRef ref,
    required List<Task> allTasks,
    DateTime? targetDate,
  });

  /// 处理 dueDate（用于跨区域拖拽）
  ///
  /// Inbox: 返回 null（不需要处理 section）
  /// Tasks: 根据 section 计算目标 dueDate
  DateTime? handleDueDate({
    required TaskSection? section,
    required Task? beforeTask,
    required Task? afterTask,
    required Task draggedTask,
  });

  /// 获取当前 section（如果适用）
  ///
  /// Inbox: 返回 null
  /// Tasks: 返回当前 section
  TaskSection? get section;

  /// 获取页面标识（用于日志）
  String get pageName;

  /// 获取拖拽 Notifier（用于自动滚动）
  ///
  /// 返回 InboxDragNotifier 或 TasksDragNotifier
  /// 用于边缘自动滚动功能
  dynamic getDragNotifier(WidgetRef ref);
}

