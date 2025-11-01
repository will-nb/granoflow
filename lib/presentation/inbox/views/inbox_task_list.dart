import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_utils.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../widgets/inbox_task_tile.dart';

class InboxTaskList extends ConsumerStatefulWidget {
  const InboxTaskList({
    super.key,
    required this.tasks,
  });

  final List<Task> tasks;

  @override
  ConsumerState<InboxTaskList> createState() => _InboxTaskListState();
}

class _InboxTaskListState extends ConsumerState<InboxTaskList> {
  late List<Task> _tasks;

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

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    // 计算新的 sortIndex（使用我们修复后的逻辑）
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? rootTasks[targetIndex - 1].sortIndex : null;
    final after = targetIndex < rootTasks.length - 1
        ? rootTasks[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);
    final task = rootTasks[oldIndex];
    
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

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();

    // 过滤出根任务
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    if (rootTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rootTasks.length,
      onReorder: _handleReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final task = rootTasks[index];
        return InboxTaskTile(
          key: ValueKey('inbox-${task.id}'),
          task: task,
          leading: ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: Icon(Icons.drag_indicator_rounded, size: 20),
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 0, right: 16, top: 12, bottom: 12),
        );
      },
    );
  }
}
