import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/inbox_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../common/drag/cross_section_draggable_list.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/task_collection_utils.dart';
import 'inbox_delegate.dart';

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
  int? _expandedTaskId; // 手风琴模式：记录当前展开的任务ID
  late final controller = ref.read(inboxListControllerProvider);

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 状态的任务（双重保障，Repository 层已经过滤）
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();

    // 过滤出根任务（parentId == null 或者 parent 不在 inbox 中）
    final rootTasks = collectRoots(filteredTasks)
        // 排除项目和里程碑类型的根任务（只显示普通任务）
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    if (rootTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final delegate = InboxDelegate(
      ref: ref,
      allTasks: filteredTasks,
      expandedTaskId: _expandedTaskId,
      onExpansionChanged: (taskId) {
        setState(() {
          _expandedTaskId = taskId;
        });
      },
    );

    return CrossSectionDraggableList<Task>(
      items: rootTasks,
      delegate: delegate,
      controller: controller,
      sectionId: 'inbox',
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      showPromoteTarget: false,
      dragStateProvider: inboxDragProvider,
    );
  }
}
