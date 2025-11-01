import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/tasks_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../common/drag/cross_section_draggable_list.dart';
import '../../common/drag/draggable_list_controller.dart';
import '../../common/drag/draggable_list_delegate.dart';
import '../utils/hierarchy_utils.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../widgets/ancestor_task_chain.dart';
import '../widgets/parent_task_header.dart';
import 'task_section_delegate.dart';
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
  late DraggableListController<Task> _controller;
  late TaskSectionDelegate _delegate;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
    _controller = ref.read(taskSectionListControllerProvider(widget.section));
    _delegate = TaskSectionDelegate(
      section: widget.section,
      ref: ref,
      getDisplayedParentIds: _getDisplayedParentIdsUpTo,
      tasks: _roots,  // Pass tasks to delegate
    );
  }

  @override
  void didUpdateWidget(TaskSectionTaskModeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roots != widget.roots) {
      _roots = List<Task>.from(widget.roots);
      // Recreate delegate with updated tasks
      _delegate = TaskSectionDelegate(
        section: widget.section,
        ref: ref,
        getDisplayedParentIds: _getDisplayedParentIdsUpTo,
        tasks: _roots,
      );
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  // 添加一个状态来控制拖拽模式
  bool _useLongPressDrag = false;

  @override
  Widget build(BuildContext context) {
    if (_roots.isEmpty) {
      return const SizedBox.shrink();
    }

    return CrossSectionDraggableList<Task>(
      items: _roots,
      delegate: _delegate,
      controller: _controller,
      sectionId: widget.section.name,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      showPromoteTarget: widget.section != TaskSection.overdue,
      dragStateProvider: tasksDragProvider,
      useLongPressDrag: _useLongPressDrag,
    );
  }

  /// 获取到当前索引为止已经显示的父任务 ID 集合
  /// 
  /// 用于避免重复显示父任务
  Set<int> _getDisplayedParentIdsUpTo(int index) {
    final displayedParentIds = <int>{};
    for (int i = 0; i < index; i++) {
      if (i < _controller.items.length) {
        final task = _controller.items[i];
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
  ConsumerState<TaskSectionProjectModePanel> createState() => _TaskSectionProjectModePanelState();
}

class _TaskSectionProjectModePanelState
    extends ConsumerState<TaskSectionProjectModePanel> {
  late List<Task> _roots;
  late DraggableListController<Task> _controller;
  late TaskSectionDelegate _delegate;
  
  // 添加一个状态来控制拖拽模式
  bool _useLongPressDrag = false;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
    _controller = ref.read(taskSectionListControllerProvider(widget.section));
    _delegate = TaskSectionDelegate(
      section: widget.section,
      ref: ref,
      getDisplayedParentIds: (_) => <int>{}, // Project mode doesn't use parent chain display
      tasks: _roots,  // Pass tasks to delegate
    );
  }

  @override
  void didUpdateWidget(TaskSectionProjectModePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!task_list_utils.listEquals(oldWidget.roots, widget.roots)) {
      _roots = List<Task>.from(widget.roots);
      // Recreate delegate with updated tasks
      _delegate = TaskSectionDelegate(
        section: widget.section,
        ref: ref,
        getDisplayedParentIds: (_) => <int>{},
        tasks: _roots,
      );
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrossSectionDraggableList<Task>(
      items: _roots,
      delegate: ProjectModeDelegate(
        section: widget.section,
        ref: ref,
        baseDelegate: _delegate,
      ),
      controller: _controller,
      sectionId: '${widget.section.name}-project',
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      showPromoteTarget: false,
      dragStateProvider: tasksDragProvider,
      useLongPressDrag: _useLongPressDrag,
    );
  }
}

/// Project mode delegate that wraps tasks in cards
class ProjectModeDelegate extends DraggableListDelegate<Task> {
  final TaskSection section;
  final WidgetRef ref;
  final TaskSectionDelegate baseDelegate;
  
  ProjectModeDelegate({
    required this.section,
    required this.ref,
    required this.baseDelegate,
  });
  
  // Forward all methods to base delegate
  @override
  bool canReorder(Task item, int oldIndex, int newIndex) =>
      baseDelegate.canReorder(item, oldIndex, newIndex);
  
  @override
  Future<void> onReorder(Task item, int oldIndex, int newIndex) =>
      baseDelegate.onReorder(item, oldIndex, newIndex);
  
  @override
  bool canAcceptExternal(Task draggedItem, int targetIndex) =>
      baseDelegate.canAcceptExternal(draggedItem, targetIndex);
  
  @override
  Future<void> onAcceptExternal(Task draggedItem, int targetIndex) =>
      baseDelegate.onAcceptExternal(draggedItem, targetIndex);
  
  @override
  bool canMakeChild(Task draggedItem, Task targetItem) =>
      baseDelegate.canMakeChild(draggedItem, targetItem);
  
  @override
  Future<void> onMakeChild(Task draggedItem, Task targetItem) =>
      baseDelegate.onMakeChild(draggedItem, targetItem);
  
  @override
  bool canPromoteToRoot(Task item) => baseDelegate.canPromoteToRoot(item);
  
  @override
  Future<void> onPromoteToRoot(Task item) => baseDelegate.onPromoteToRoot(item);
  
  @override
  String getItemId(Task item) => baseDelegate.getItemId(item);
  
  // Custom item builder with card wrapper
  @override
  Widget buildItem(BuildContext context, Task item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
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
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_indicator_rounded),
                  ),
                  Expanded(
                    child: ProjectNodeHeader(
                      task: item,
                      section: section,
                    ),
                  ),
                ],
              ),
              TaskTreeTile(
                section: section,
                rootTask: item,
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
      ),
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
        debugPrint('[TaskWithParentChain] 任务无父任务，直接显示: taskId=${task.id}, title=${task.title}');
      }
      return TaskTreeTile(
        section: section,
        rootTask: task,
        editMode: false,
      );
    }

    if (kDebugMode) {
      debugPrint('[TaskWithParentChain] 任务有父任务，准备显示父任务链: taskId=${task.id}, parentId=${task.parentId}, section=${section.name}');
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