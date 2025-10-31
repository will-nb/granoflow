import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/hierarchy_utils.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../utils/sort_index_utils.dart';
import '../widgets/ancestor_task_chain.dart';
import '../widgets/parent_task_header.dart';
import '../../widgets/reorderable_proxy_decorator.dart';
import 'task_tree_tile.dart';

class TaskSectionTaskModeList extends ConsumerStatefulWidget {
  const TaskSectionTaskModeList({
    super.key,
    required this.section,
    required this.roots,
  });

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<TaskSectionTaskModeList> createState() => _TaskSectionTaskModeListState();
}

class _TaskSectionTaskModeListState extends ConsumerState<TaskSectionTaskModeList> {
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
        return ReorderableDragStartListener(
          key: ValueKey('task-${task.id}'),
          index: index,
          child: _TaskWithParentChain(
            section: widget.section,
            task: task,
            displayedParentIds: _getDisplayedParentIdsUpTo(index),
          ),
        );
      },
    );
  }

  /// 获取到当前索引为止已经显示的父任务 ID 集合
  /// 
  /// 用于避免重复显示父任务
  Set<int> _getDisplayedParentIdsUpTo(int index) {
    final displayedParentIds = <int>{};
    for (int i = 0; i < index; i++) {
      final task = _roots[i];
      if (task.parentId != null) {
        displayedParentIds.add(task.parentId!);
      }
    }
    return displayedParentIds;
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }
    setState(() {
      final task = _roots.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _roots.insert(targetIndex, task);
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _roots.length - 1
        ? _roots[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);
    final task = _roots[targetIndex];
    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update sort order: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
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
  ConsumerState<TaskSectionProjectModePanel> createState() => _TaskSectionProjectModePanelState();
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

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roots.length,
      onReorder: _handleReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final task = _roots[index];
        return Card(
          key: ValueKey('${task.id}-${task.sortIndex}'),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }
    setState(() {
      final task = _roots.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _roots.insert(targetIndex, task);
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _roots.length - 1
        ? _roots[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);
    final task = _roots[targetIndex];
    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update sort order: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
  }
}

/// 任务及其父任务链的包装组件
/// 
/// 在显示任务之前，先显示它的祖先任务链和父任务
class _TaskWithParentChain extends ConsumerWidget {
  const _TaskWithParentChain({
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
      return TaskTreeTile(
        section: section,
        rootTask: task,
        editMode: false,
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
            AncestorTaskChain(
              taskId: task.id,
              currentSection: section,
            ),
            // 显示父任务（如果还没有显示过）
            if (!parentAlreadyDisplayed)
              ParentTaskHeader(
                parentTask: parent,
                currentSection: section,
                depth: 0,
              ),
            // 显示当前任务
            TaskTreeTile(
              section: section,
              rootTask: task,
              editMode: false,
            ),
          ],
        );
      },
      loading: () => TaskTreeTile(
        section: section,
        rootTask: task,
        editMode: false,
      ),
      error: (_, __) => TaskTreeTile(
        section: section,
        rootTask: task,
        editMode: false,
      ),
    );
  }
}

/// Provider: 获取父任务
final parentTaskProvider = FutureProvider.family<Task?, int>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return taskRepository.findById(parentId);
});
