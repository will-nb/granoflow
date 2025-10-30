import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../utils/sort_index_utils.dart';
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
          child: TaskTreeTile(
            section: widget.section,
            rootTask: task,
            editMode: false,
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

