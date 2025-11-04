import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/app_spacing_tokens.dart';
import '../../../data/models/task.dart';
import '../utils/hierarchy_utils.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../utils/sort_index_utils.dart';
import '../widgets/ancestor_task_chain.dart';
import '../widgets/parent_task_header.dart';
import '../../widgets/reorderable_proxy_decorator.dart';
import '../../widgets/task_drag_intent_helper.dart';
import '../../common/drag/task_drag_intent_target.dart';
import 'task_tree_tile.dart';
import 'task_tree_tile/task_tree_tile_header.dart';

class TaskSectionTaskModeList extends ConsumerStatefulWidget {
  const TaskSectionTaskModeList({
    super.key,
    required this.section,
    required this.roots,
  });

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<TaskSectionTaskModeList> createState() =>
      _TaskSectionTaskModeListState();
}

class _TaskSectionTaskModeListState
    extends ConsumerState<TaskSectionTaskModeList> {
  late List<Task> _roots;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
  }

  @override
  void didUpdateWidget(TaskSectionTaskModeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roots != widget.roots) {
      _roots = List<Task>.from(widget.roots);
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    // 计算新的 sortIndex 和 dueAt
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _roots.length - 1
        ? _roots[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);

    // 计算新的 dueAt：同一区域内，使用相邻任务的 dueAt
    DateTime? newDueAt;
    if (targetIndex > 0 && _roots[targetIndex - 1].dueAt != null) {
      newDueAt = _roots[targetIndex - 1].dueAt;
    } else if (targetIndex < _roots.length - 1 &&
        _roots[targetIndex + 1].dueAt != null) {
      newDueAt = _roots[targetIndex + 1].dueAt;
    } else {
      newDueAt = _roots[oldIndex].dueAt;
    }

    final task = _roots[oldIndex];
    final taskService = ref.read(taskServiceProvider);

    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex, dueAt: newDueAt),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update task order: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roots.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roots.length,
      onReorder: _handleReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: ReorderableProxyDecorator.build,
      itemBuilder: (context, index) {
        final task = _roots[index];
        return TaskDragIntentTarget.surface(
          key: ValueKey('task-${task.id}'),
          meta: TaskDragIntentMeta(
            page: 'Tasks',
            targetType: 'taskSurface',
            targetId: task.id,
            targetTaskId: task.id,
          ),
          canAccept: (draggedTask, _) =>
              TaskDragIntentHelper.canAcceptAsChild(draggedTask, task),
          onPerform: (draggedTask, ref, context, l10n) async {
            return TaskDragIntentHelper.handleDropOnTask(
              draggedTask,
              task,
              context,
              ref,
              l10n,
            );
          },
          // 已移除 ReorderableDragStartListener，改用 StandardDraggable 启动拖拽
          child: TaskWithParentChain(
            section: widget.section,
            task: task,
            displayedParentIds: _getDisplayedParentIdsUpTo(index),
          ),
        );
      },
    );
  }

  /// 获取到当前索引为止已经显示的父任务 ID 集合
  Set<int> _getDisplayedParentIdsUpTo(int index) {
    final displayedParentIds = <int>{};
    for (int i = 0; i < index; i++) {
      if (i < _roots.length) {
        final task = _roots[i];
        if (task.parentId != null) {
          displayedParentIds.add(task.parentId!);
        }
      }
    }
    return displayedParentIds;
  }
}

class TaskSectionProjectModePanel extends ConsumerStatefulWidget {
  const TaskSectionProjectModePanel({
    super.key,
    required this.section,
    required this.roots,
  });

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<TaskSectionProjectModePanel> createState() =>
      _TaskSectionProjectModePanelState();
}

class _TaskSectionProjectModePanelState
    extends ConsumerState<TaskSectionProjectModePanel> {
  late List<Task> _roots;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
  }

  @override
  void didUpdateWidget(TaskSectionProjectModePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!task_list_utils.listEquals(oldWidget.roots, widget.roots)) {
      _roots = List<Task>.from(widget.roots);
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    // 计算新的 sortIndex 和 dueAt
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _roots.length - 1
        ? _roots[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);

    // 计算新的 dueAt
    DateTime? newDueAt;
    if (targetIndex > 0 && _roots[targetIndex - 1].dueAt != null) {
      newDueAt = _roots[targetIndex - 1].dueAt;
    } else if (targetIndex < _roots.length - 1 &&
        _roots[targetIndex + 1].dueAt != null) {
      newDueAt = _roots[targetIndex + 1].dueAt;
    } else {
      newDueAt = _roots[oldIndex].dueAt;
    }

    final task = _roots[oldIndex];
    final taskService = ref.read(taskServiceProvider);

    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex, dueAt: newDueAt),
      );

      // 批量重排目标日期同一天的所有任务的sortIndex
      final taskRepository = ref.read(taskRepositoryProvider);
      final sortIndexService = ref.read(sortIndexServiceProvider);

      // 查询所有pending状态的普通任务（Tasks页面显示的任务）
      // 在新架构下，普通任务没有关联项目或里程碑
      final allPendingTasks = await taskRepository.listAll();
      final pendingRegularTasks = allPendingTasks
          .where(
            (t) =>
                t.status == TaskStatus.pending &&
                t.projectId == null &&
                t.milestoneId == null,
          )
          .toList();

      // 批量重排目标日期同一天的任务
      await sortIndexService.reorderTasksForSameDate(
        allTasks: pendingRegularTasks,
        targetDate: newDueAt,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update task order: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roots.length,
      onReorder: _handleReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: ReorderableProxyDecorator.build,
      itemBuilder: (context, index) {
        final task = _roots[index];
        return Card(
          key: ValueKey('project-${task.id}'),
          margin: EdgeInsets.only(
            bottom: Theme.of(context).extension<AppSpacingTokens>()?.sectionInternalSpacing ?? 8.0,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Theme.of(context).extension<AppSpacingTokens>()?.cardHorizontalPadding ?? 16.0,
              vertical: Theme.of(context).extension<AppSpacingTokens>()?.cardVerticalPadding ?? 8.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                    Expanded(
                      child: ProjectNodeHeader(
                        task: task,
                        section: widget.section,
                      ),
                    ),
                  ],
                ),
                TaskTreeTile(
                  section: widget.section,
                  rootTask: task,
                  editMode: true,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 任务及其父任务链的包装组件
///
/// 在显示任务之前，先显示它的祖先任务链和父任务
class TaskWithParentChain extends ConsumerWidget {
  const TaskWithParentChain({
    super.key,
    required this.section,
    required this.task,
    required this.displayedParentIds,
  });

  final TaskSection section;
  final Task task;
  final Set<int> displayedParentIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 如果任务没有父任务，直接显示任务
    if (task.parentId == null) {
      if (kDebugMode) {
        debugPrint(
          '[TaskWithParentChain] 任务无父任务，直接显示: taskId=${task.id}, title=${task.title}',
        );
      }
      return TaskTreeTile(section: section, rootTask: task, editMode: false);
    }

    if (kDebugMode) {
      debugPrint(
        '[TaskWithParentChain] 任务有父任务，准备显示父任务链: taskId=${task.id}, parentId=${task.parentId}, section=${section.name}',
      );
    }

    // 检查父任务是否是项目或里程碑
    final parentAsync = ref.watch(parentTaskProvider(task.parentId!));

    return parentAsync.when(
      data: (parent) {
        if (parent == null || isProjectOrMilestone(parent)) {
          // 父任务不存在或是项目/里程碑，直接显示任务
          return TaskTreeTile(
            section: section,
            rootTask: task,
            editMode: false,
          );
        }

        // 检查父任务是否已经显示过（避免重复显示）
        final parentAlreadyDisplayed = displayedParentIds.contains(parent.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示祖先任务链
            AncestorTaskChain(taskId: task.id, currentSection: section),
            // 显示父任务（如果还没有显示过）
            if (!parentAlreadyDisplayed)
              ParentTaskHeader(
                parentTask: parent,
                currentSection: section,
                depth: 0,
              ),
            // 显示当前任务
            TaskTreeTile(section: section, rootTask: task, editMode: false),
          ],
        );
      },
      loading: () =>
          TaskTreeTile(section: section, rootTask: task, editMode: false),
      error: (_, __) =>
          TaskTreeTile(section: section, rootTask: task, editMode: false),
    );
  }
}

/// Provider: 获取父任务
final parentTaskProvider = FutureProvider.family<Task?, int>((
  ref,
  parentId,
) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return taskRepository.findById(parentId);
});
