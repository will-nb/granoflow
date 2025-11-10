import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/theme/app_spacing_tokens.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../utils/list_comparison_utils.dart' as task_list_utils;
import '../../utils/sort_index_utils.dart';
import 'task_tree_tile_actions.dart';

/// 项目子任务编辑器组件
/// 用于编辑模式下显示和重排子任务
class ProjectChildrenEditor extends ConsumerStatefulWidget {
  const ProjectChildrenEditor({
    super.key,
    required this.nodes,
    required this.parentTask,
  });

  final List<TaskTreeNode> nodes;
  final Task parentTask;

  @override
  ConsumerState<ProjectChildrenEditor> createState() =>
      _ProjectChildrenEditorState();
}

class _ProjectChildrenEditorState extends ConsumerState<ProjectChildrenEditor> {
  late List<TaskTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List<TaskTreeNode>.from(widget.nodes);
  }

  @override
  void didUpdateWidget(covariant ProjectChildrenEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!task_list_utils.treeEquals(oldWidget.nodes, widget.nodes)) {
      _nodes = List<TaskTreeNode>.from(widget.nodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = Theme.of(context).extension<AppSpacingTokens>();
    final spacingTokens = spacing ?? AppSpacingTokens.light;
    if (_nodes.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacingTokens.cardHorizontalPadding,
          vertical: spacingTokens.cardVerticalPadding,
        ),
        child: Text(l10n.taskListNoSubtasks),
      );
    }
    return ReorderableListView.builder(
      key: ValueKey('children-${widget.parentTask.id}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _nodes.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final node = _nodes[index];
        return ListTile(
          key: ValueKey('child-${node.task.id}-${node.task.sortIndex}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(node.task.title),
            subtitle: Text('ID: ${node.task.id}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: l10n.actionAddSubtask,
                icon: const Icon(Icons.add),
                onPressed: () =>
                    showAddSubtaskDialog(context, ref, node.task.id),
              ),
              IconButton(
                tooltip: l10n.taskListRenameDialogTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showRenameDialog(context, ref, node.task),
              ),
              IconButton(
                tooltip: l10n.actionArchive,
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => archiveTask(context, ref, node.task.id),
              ),
            ],
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
      final node = _nodes.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _nodes.insert(targetIndex, node);
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0
        ? _nodes[targetIndex - 1].task.sortIndex
        : null;
    final after = targetIndex < _nodes.length - 1
        ? _nodes[targetIndex + 1].task.sortIndex
        : null;
    final updatedNode = _nodes[targetIndex];
    final newSortIndex = calculateSortIndex(before, after);

    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await taskService.updateDetails(
        taskId: updatedNode.task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );

      // 批量重排该父任务的所有子任务的sortIndex
      final taskRepository = ref.read(taskRepositoryProvider);
      final sortIndexService = ref.read(sortIndexServiceProvider);
      final parentId = updatedNode.task.parentId;
      if (parentId != null) {
        final allChildren = await taskRepository.listChildren(parentId);
        await sortIndexService.reorderChildrenTasks(children: allChildren);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to update child sort: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
  }
}

