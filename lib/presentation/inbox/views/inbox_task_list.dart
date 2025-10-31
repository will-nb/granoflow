import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/utils/sort_index_utils.dart';
import '../../widgets/reorderable_proxy_decorator.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      buildDefaultDragHandles: false,
      proxyDecorator: ReorderableProxyDecorator.build,
      onReorder: _handleReorder,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return ReorderableDragStartListener(
          key: ValueKey('inbox-${task.id}'),
          index: index,
          child: InboxTaskTile(task: task),
        );
      },
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    setState(() {
      final task = _tasks.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _tasks.insert(targetIndex, task);
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _tasks[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _tasks.length - 1 ? _tasks[targetIndex + 1].sortIndex : null;
    final updatedTask = _tasks[targetIndex];
    final newSortIndex = calculateSortIndex(before, after);

    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);

    try {
      await taskService.updateDetails(
        taskId: updatedTask.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update inbox sort order: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskListSortError)),
      );
    }
  }
}

