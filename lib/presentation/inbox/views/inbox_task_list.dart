import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/inbox_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../common/task_list/inbox_task_list_config.dart';
import '../../common/task_list/task_list_tree_builder.dart';
import '../../common/task_list/task_list_flattener.dart';
import '../../common/task_list/task_list_drag_builder.dart';
import '../../common/task_list/task_list_edge_auto_scroll.dart';

/// Inbox 页面的任务列表组件
///
/// 提供可拖拽排序的任务列表，支持以下功能：
/// - 列表内任务重排序（拖拽改变顺序）
/// - 跨区域拖拽（将任务拖到其他任务上使其成为子任务）
/// - 拖拽时的视觉反馈（间隔线）
/// - 层级缩进显示（每个层级缩进 20px）
///
/// 使用 [TaskTreeNode] 和 [flattenTree] 构建层级结构，并通过
/// [TaskDragIntentTarget] 处理跨区域拖拽和目标任务识别。
///
/// 注意：
/// - 显示完整的任务层级结构（包括所有子任务）
/// - 排序功能只影响根任务（子任务不参与排序）
/// - 插入目标在根任务之间和子任务之间都显示
/// - 自动过滤掉已删除（trashed）状态的任务
/// - 自动过滤掉项目（project）和里程碑（milestone）类型的任务
class InboxTaskList extends ConsumerStatefulWidget {
  /// 创建 Inbox 任务列表组件
  ///
  /// [tasks] 是要显示的任务列表
  const InboxTaskList({super.key, required this.tasks});

  /// 要显示的任务列表
  final List<Task> tasks;

  @override
  ConsumerState<InboxTaskList> createState() => _InboxTaskListState();
}

class _InboxTaskListState extends ConsumerState<InboxTaskList> {
  /// 内部维护的任务列表副本
  ///
  /// 用于在组件更新时保持列表状态的稳定性
  late List<Task> _tasks;

  /// 配置实例
  final _config = InboxTaskListConfig();

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant InboxTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _tasks = List<Task>.from(widget.tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取虚拟字段 levelMap 和 childrenMap
    final levelMapAsync = ref.watch(inboxTaskLevelMapProvider);
    final childrenMapAsync = ref.watch(inboxTaskChildrenMapProvider);

    // 使用 AsyncValue.when 处理异步加载
    return levelMapAsync.when(
      data: (levelMap) {
        return childrenMapAsync.when(
          data: (childrenMap) {
            // 过滤掉 trashed 状态的任务
            final filteredTasks = _tasks
                .where((task) => task.status != TaskStatus.trashed)
                .toList();

            // 构建任务层级树（使用工具类）
            final taskTrees = TaskListTreeBuilder.buildTaskTree(filteredTasks);

            // 获取展开状态（默认所有任务都是收缩的）
            final expandedTaskIds = ref.watch(inboxExpandedTaskIdProvider);

            // 扁平化为带深度的任务列表（根据展开状态，使用工具类）
            final flattenedTasks = <FlattenedTaskNode>[];
            for (final tree in taskTrees) {
              flattenedTasks.addAll(
                TaskListFlattener.flattenTreeWithExpansion(
                  tree,
                  depth: 0,
                  expandedTaskIds: expandedTaskIds,
                ),
              );
            }

            // 获取拖拽状态
            final dragState = ref.watch(inboxDragProvider);

            if (flattenedTasks.isEmpty) {
              return const SizedBox.shrink();
            }

            // 创建任务 ID 到是否有子任务的映射（用于显示展开/收缩按钮，使用工具类）
            final taskIdToHasChildren = <int, bool>{};
            for (final tree in taskTrees) {
              TaskListTreeBuilder.populateHasChildrenMap(
                tree,
                taskIdToHasChildren,
                filteredTasks,
              );
            }

            // 获取根任务列表（仅用于排序逻辑和插入目标）
            final rootTasks = collectRoots(filteredTasks);

            // 创建任务映射：任务 ID -> 根任务索引（仅用于根任务）
            final taskIdToIndex = <int, int>{};
            for (var i = 0; i < rootTasks.length; i++) {
              taskIdToIndex[rootTasks[i].id] = i;
            }

            // 获取拖拽 Notifier
            final dragNotifier = ref.read(inboxDragProvider.notifier);

            // 使用 TaskListDragBuilder 构建拖拽 UI
            final dragWidgets = TaskListDragBuilder.buildTaskListDragUI(
              flattenedTasks: flattenedTasks,
              rootTasks: rootTasks,
              taskIdToIndex: taskIdToIndex,
              taskIdToHasChildren: taskIdToHasChildren,
              levelMap: levelMap,
              childrenMap: childrenMap,
              expandedTaskIds: expandedTaskIds,
              filteredTasks: filteredTasks,
              config: _config,
              dragState: dragState,
              dragNotifier: dragNotifier,
              ref: ref,
              onExpandedChanged: (newExpanded) {
                final expandedNotifier =
                    ref.read(inboxExpandedTaskIdProvider.notifier);
                expandedNotifier.state = newExpanded;
              },
              onDragStarted: (task) {
                // 使用虚拟字段 levelMap 和 childrenMap
                final taskLevelForDrag = levelMap[task.id] ?? 1;

                // 获取展开状态管理器
                final expandedNotifier =
                    ref.read(inboxExpandedTaskIdProvider.notifier);
                final currentExpanded = Set<int>.from(expandedNotifier.state);

                if (taskLevelForDrag == 1) {
                  // 根任务：收缩所有子任务
                  final childTaskIds = childrenMap[task.id] ?? <int>{};
                  final updatedExpanded = Set<int>.from(currentExpanded);
                  updatedExpanded.removeAll(childTaskIds);
                  expandedNotifier.state = updatedExpanded;
                } else {
                  // 子任务：检查是否展开
                  final isExpanded = expandedTaskIds.contains(task.id);
                  if (!isExpanded) {
                    // 禁止拖拽未展开的任务
                    return;
                  }
                  // 收缩自己的子任务
                  final childTaskIds = childrenMap[task.id] ?? <int>{};
                  final updatedExpanded = Set<int>.from(currentExpanded);
                  updatedExpanded.removeAll(childTaskIds);
                  expandedNotifier.state = updatedExpanded;
                }

                // 在 onDragStarted 时还没有全局位置，使用 Offset.zero 作为占位符
                // 实际位置会在第一次 onDragUpdate 时更新
                if (kDebugMode) {
                  debugPrint(
                    '[DnD] {event: onDragStarted, page: Inbox, taskId: ${task.id}, title: "${task.title}", placeholderPosition: Offset.zero}',
                  );
                }
                dragNotifier.startDrag(task, Offset.zero);
              },
              onDragUpdate: (details) {
                // 更新拖拽位置（全局坐标）
                dragNotifier.updateDragPosition(details.globalPosition);

                // 边缘自动滚动
                TaskListEdgeAutoScroll.handleEdgeAutoScroll(
                  context,
                  details.globalPosition,
                  _config,
                  ref,
                );
              },
              onDragEnd: () {
                // 拖拽结束处理（由 TaskDragIntentTarget 的 onPerform 处理）
                dragNotifier.endDrag();
              },
              depth: 20.0, // 每个层级缩进 20px
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: dragWidgets,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            debugPrint('Error loading children map: $error');
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        debugPrint('Error loading level map: $error');
        return const SizedBox.shrink();
      },
    );
  }
}
