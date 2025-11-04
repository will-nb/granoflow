import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/project.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../utils/tag_utils.dart';
import '../../utils/date_utils.dart';
import '../../widgets/status_chip.dart';
import 'project_edit_sheet.dart';
import 'project_card_actions.dart';
import 'project_card_dialogs.dart';

/// 项目头部行组件
/// 
/// 显示项目标题、截止日期、标签和操作菜单
class ProjectHeaderRow extends ConsumerWidget {
  const ProjectHeaderRow({
    super.key,
    required this.project,
    required this.isExpanded,
  });

  final Project project;
  final bool isExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final deadlineLabel = formatDeadline(context, project.dueAt);
    final tagChips = project.tags
        .map((slug) => buildModernTag(context, slug))
        .whereType<Widget>()
        .toList(growable: false);
    final overdue =
        project.dueAt != null && project.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildProjectTitle(context, project),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(context, ref, value),
              itemBuilder: (context) => _buildMenuItems(context, project),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (deadlineLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${l10n.projectDeadlineLabel} $deadlineLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (tagChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
          ),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StatusChip(
              label: l10n.projectStatusOverdue,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildProjectTitle(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge;

    // 根据项目状态设置标题样式
    TextStyle? titleStyle;
    if (project.status == TaskStatus.completedActive) {
      titleStyle = textStyle?.copyWith(
        decoration: TextDecoration.lineThrough,
        color: theme.colorScheme.onSurfaceVariant,
      );
    } else if (project.status == TaskStatus.archived) {
      titleStyle = textStyle?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
    } else if (project.status == TaskStatus.trashed) {
      titleStyle = textStyle?.copyWith(
        color: theme.colorScheme.error,
      );
    }

    return Text(
      project.title,
      style: titleStyle ?? textStyle,
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    Project project,
  ) {
    final l10n = AppLocalizations.of(context);
    final items = <PopupMenuEntry<String>>[];

    // 编辑项目 - 所有状态显示
    items.add(
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            const Icon(Icons.edit_outlined, size: 20),
            const SizedBox(width: 12),
            const Text('编辑项目'),
          ],
        ),
      ),
    );

    // 根据项目状态显示不同的菜单项
    if (project.status == TaskStatus.trashed) {
      // 回收站状态：显示恢复
      items.add(
        PopupMenuItem<String>(
          value: 'restore',
          child: Row(
            children: [
              const Icon(Icons.restore_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.trashRestoreAction),
            ],
          ),
        ),
      );
    } else {
      // 活跃/已完成状态：显示完成、归档、删除
      if (project.status == TaskStatus.pending ||
          project.status == TaskStatus.doing) {
        items.add(
          PopupMenuItem<String>(
            value: 'complete',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 12),
                Text(l10n.actionMarkCompleted),
              ],
            ),
          ),
        );
      }

      if (project.status == TaskStatus.pending ||
          project.status == TaskStatus.doing ||
          project.status == TaskStatus.completedActive) {
        items.add(
          PopupMenuItem<String>(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive_outlined, size: 20),
                const SizedBox(width: 12),
                Text(l10n.taskArchiveAction),
              ],
            ),
          ),
        );

        items.add(
          PopupMenuItem<String>(
            value: 'trash',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20),
                const SizedBox(width: 12),
                Text(l10n.actionMoveToTrash),
              ],
            ),
          ),
        );
      }

      if (project.status == TaskStatus.archived) {
        items.add(
          PopupMenuItem<String>(
            value: 'trash',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20),
                const SizedBox(width: 12),
                Text(l10n.actionMoveToTrash),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await _editProject(context, ref, project);
        break;
      case 'complete':
        final confirmed = await confirmProjectComplete(context, ref, project);
        if (confirmed != null) {
          await completeProject(
            context,
            ref,
            project.id,
            archiveTasks: confirmed == true,
          );
        }
        break;
      case 'archive':
        final confirmed = await confirmProjectArchive(context, ref, project);
        if (confirmed != null) {
          await archiveProject(
            context,
            ref,
            project.id,
            archiveTasks: confirmed == true,
          );
        }
        break;
      case 'trash':
        await trashProject(context, ref, project.id);
        break;
      case 'restore':
        await restoreProject(context, ref, project.id);
        break;
    }
  }

  Future<void> _editProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ProjectEditSheet(project: project),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('项目已更新')),
      );
    }
  }
}

