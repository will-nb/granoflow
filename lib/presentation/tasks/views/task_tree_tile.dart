import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/task_section_utils.dart';
import '../../../data/models/task.dart';
import '../../widgets/error_banner.dart';
import 'task_leaf_tile.dart';
import '../widgets/parent_task_in_own_section.dart';
import 'task_tree_tile/task_tree_tile_editor.dart';
import 'task_tree_tile/task_tree_tile_header.dart';

class TaskTreeTile extends ConsumerWidget {
  const TaskTreeTile({
    super.key,
    required this.section,
    required this.rootTask,
    required this.editMode,
    this.padding,
  });

  final TaskSection section;
  final Task rootTask;
  final bool editMode;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      debugPrint('[TaskTreeTile] build - taskId=${rootTask.id}, section=${section.name}, editMode=$editMode');
    }
    final treeAsync = ref.watch(taskTreeProvider(rootTask.id));
    return treeAsync.when(
      data: (tree) {
        if (kDebugMode) {
          debugPrint('[TaskTreeTile] data loaded - taskId=${rootTask.id}, children.length=${tree.children.length}');
        }
        if (editMode) {
          return ProjectTreeView(
            tree: tree,
            section: section,
            padding: padding,
          );
        }
        return TaskTreeView(tree: tree, section: section);
      },
      loading: () {
        if (kDebugMode) {
          debugPrint('[TaskTreeTile] loading - taskId=${rootTask.id}');
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[TaskTreeTile] error - taskId=${rootTask.id}, error=$error');
        }
        return ErrorBanner(message: '$error');
      },
    );
  }
}

class TaskTreeView extends ConsumerWidget {
  const TaskTreeView({super.key, required this.tree, required this.section});

  final TaskTreeNode tree;
  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      debugPrint('[TaskTreeView] build - taskId=${tree.task.id}, section=${section.name}, children.length=${tree.children.length}');
    }
    
    if (tree.children.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TaskTreeView] 没有子任务，显示 TaskLeafTile - taskId=${tree.task.id}');
      }
      return TaskLeafTile(task: tree.task, depth: 0);
    }
    
    // 获取当前任务的第一个子任务来判断区域
    final firstChild = tree.children.first.task;
    final childSection = TaskSectionUtils.getSectionForDate(firstChild.dueAt);
    final parentSection = TaskSectionUtils.getSectionForDate(tree.task.dueAt);
    
    if (kDebugMode) {
      debugPrint('[TaskTreeView] 有子任务 - parentId=${tree.task.id}, childSection=$childSection, parentSection=$parentSection, currentSection=$section');
    }
    
    // 只有当子任务和父任务在同一区域时，才以父任务为主体显示
    if (childSection == parentSection && childSection == section) {
      if (kDebugMode) {
        debugPrint('[TaskTreeView] 父子同区域，显示 ParentTaskInOwnSection - parentId=${tree.task.id}');
      }
      return ParentTaskInOwnSection(
        parentTask: tree.task,
        currentSection: section,
      );
    }
    
    // 否则只显示当前任务
    if (kDebugMode) {
      debugPrint('[TaskTreeView] 父子不同区域，只显示 TaskLeafTile - taskId=${tree.task.id}');
    }
    return TaskLeafTile(task: tree.task, depth: 0);
  }
}

class ProjectTreeView extends ConsumerWidget {
  const ProjectTreeView({
    super.key,
    required this.tree,
    required this.section,
    this.padding,
  });

  final TaskTreeNode tree;
  final TaskSection section;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expansionState = ref.watch(expandedRootTaskIdProvider);
    final expanded = expansionState == tree.task.id;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        initialOpenPanelValue: expanded ? tree.task.id : null,
        expansionCallback: (panelIndex, isExpanded) {
          ref.read(expandedRootTaskIdProvider.notifier).state = isExpanded
              ? null
              : tree.task.id;
        },
        children: [
          ExpansionPanelRadio(
            value: tree.task.id,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return ProjectNodeHeader(task: tree.task, section: section);
            },
            body: ProjectChildrenEditor(
              nodes: tree.children,
              parentTask: tree.task,
            ),
          ),
        ],
      ),
    );
  }
}

// ProjectNodeHeader 和 ProjectChildrenEditor 已移至独立文件
// 对话框和操作函数已移至 task_tree_tile_actions.dart
