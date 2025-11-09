import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';
import 'task_tree_tile_actions.dart';

/// 项目节点头部组件
/// 用于显示项目任务的基本信息和操作按钮
class ProjectNodeHeader extends ConsumerWidget {
  const ProjectNodeHeader({
    super.key,
    required this.task,
    required this.section,
  });

  final Task task;
  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 8),
      title: Text(task.title, style: theme.textTheme.titleMedium),
        subtitle: Text('ID: ${task.id}'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            tooltip: l10n.actionAddSubtask,
            icon: const Icon(Icons.subdirectory_arrow_right),
            onPressed: () => showAddSubtaskDialog(context, ref, task.id),
          ),
          IconButton(
            tooltip: l10n.taskListRenameDialogTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showRenameDialog(context, ref, task),
          ),
          IconButton(
            tooltip: l10n.actionArchive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => archiveTask(context, ref, task.id),
          ),
        ],
      ),
    );
  }
}

