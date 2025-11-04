import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/milestone.dart';
import '../../../data/models/project.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/tag_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/description_block.dart';
import '../widgets/error_banner.dart';
import '../widgets/project_swipe_background.dart';
import '../widgets/status_chip.dart';
import '../milestones/milestone_card.dart';
import '../widgets/empty_placeholder.dart';
import 'widgets/project_edit_sheet.dart';
import 'widgets/milestone_edit_sheet.dart';
import '../../../core/theme/ocean_breeze_color_schemes.dart';

class _ProjectSwipeConfig {
  const _ProjectSwipeConfig({
    required this.leftColor,
    required this.leftIcon,
    required this.leftLabel,
    required this.rightColor,
    required this.rightIcon,
    required this.rightLabel,
  });

  final Color leftColor;
  final IconData leftIcon;
  final String leftLabel;
  final Color rightColor;
  final IconData rightIcon;
  final String rightLabel;
}

class ProjectCard extends ConsumerWidget {
  const ProjectCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(
      projectMilestonesDomainProvider(project.projectId),
    );
    final expandedId = ref.watch(projectsExpandedTaskIdProvider);
    final isExpanded = expandedId == project.id;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final swipeConfig = _getSwipeConfig(project, theme, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey('project-${project.id}'),
        direction: DismissDirection.horizontal,
        background: projectSwipeBackground(
          color: swipeConfig.leftColor,
          icon: swipeConfig.leftIcon,
          label: swipeConfig.leftLabel,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: projectSwipeBackground(
          color: swipeConfig.rightColor,
          icon: swipeConfig.rightIcon,
          label: swipeConfig.rightLabel,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          return await _handleSwipeAction(
            context,
            ref,
            direction,
            project,
            swipeConfig,
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              final notifier = ref.read(
                projectsExpandedTaskIdProvider.notifier,
              );
              notifier.state = isExpanded ? null : project.id;
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: milestonesAsync.when(
                data: (milestones) {
                  final total = milestones.length;
                  final completed = milestones
                      .where((m) => m.status == TaskStatus.completedActive)
                      .length;
                  final progress = total == 0 ? 0.0 : completed / total;
                  final overdue =
                      project.dueAt != null &&
                      project.dueAt!.isBefore(DateTime.now());
                  final hasDescription =
                      project.description != null &&
                      project.description!.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProjectHeaderRow(
                        project: project,
                        isExpanded: isExpanded,
                      ),
                      if (hasDescription)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DescriptionBlock(
                            description: project.description!,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ProjectProgressBar(
                        progress: progress,
                        completed: completed,
                        total: total,
                        overdue: overdue,
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ProjectDetails(
                            project: project,
                            milestones: milestones,
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProjectHeaderRow(project: project, isExpanded: isExpanded),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      color: theme.colorScheme.primary,
                      minHeight: 2,
                    ),
                  ],
                ),
                error: (error, stackTrace) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProjectHeaderRow(project: project, isExpanded: isExpanded),
                    const SizedBox(height: 12),
                    ErrorBanner(message: '$error'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ProjectSwipeConfig _getSwipeConfig(
    Project project,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isActive = project.status == TaskStatus.pending ||
        project.status == TaskStatus.doing;
    final isArchived = project.status == TaskStatus.archived;
    final isTrashed = project.status == TaskStatus.trashed;
    final isCompleted = project.status == TaskStatus.completedActive;

    if (isActive) {
      // 活跃项目：右侧完成，左侧归档
      return _ProjectSwipeConfig(
        leftColor: OceanBreezeColorSchemes.softPink,
        leftIcon: Icons.archive_outlined,
        leftLabel: l10n.taskArchiveAction,
        rightColor: OceanBreezeColorSchemes.softGreen,
        rightIcon: Icons.check_circle_outline,
        rightLabel: l10n.actionMarkCompleted,
      );
    } else if (isArchived) {
      // 归档项目：右侧重启，左侧移入回收站
      return _ProjectSwipeConfig(
        leftColor: OceanBreezeColorSchemes.errorDark,
        leftIcon: Icons.delete_outline,
        leftLabel: l10n.actionMoveToTrash,
        rightColor: OceanBreezeColorSchemes.softGreen,
        rightIcon: Icons.restore_outlined,
        rightLabel: l10n.trashRestoreAction,
      );
    } else if (isTrashed) {
      // 回收站：右侧重启，左侧删除
      return _ProjectSwipeConfig(
        leftColor: OceanBreezeColorSchemes.errorDark,
        leftIcon: Icons.delete_forever,
        leftLabel: l10n.trashPermanentDeleteAction,
        rightColor: OceanBreezeColorSchemes.softGreen,
        rightIcon: Icons.restore_outlined,
        rightLabel: l10n.trashRestoreAction,
      );
    } else if (isCompleted) {
      // 完成项目：右侧重启，左侧移入回收站
      return _ProjectSwipeConfig(
        leftColor: OceanBreezeColorSchemes.errorDark,
        leftIcon: Icons.delete_outline,
        leftLabel: l10n.actionMoveToTrash,
        rightColor: OceanBreezeColorSchemes.softGreen,
        rightIcon: Icons.restore_outlined,
        rightLabel: l10n.trashRestoreAction,
      );
    }

    // 默认配置（不应该到达这里）
    return _ProjectSwipeConfig(
      leftColor: theme.colorScheme.primary,
      leftIcon: Icons.archive_outlined,
      leftLabel: l10n.taskArchiveAction,
      rightColor: theme.colorScheme.tertiary,
      rightIcon: Icons.snooze,
      rightLabel: l10n.projectSnoozeAction,
    );
  }

  Future<bool> _handleSwipeAction(
    BuildContext context,
    WidgetRef ref,
    DismissDirection direction,
    Project project,
    _ProjectSwipeConfig config,
  ) async {
    final isActive = project.status == TaskStatus.pending ||
        project.status == TaskStatus.doing;
    final isArchived = project.status == TaskStatus.archived;
    final isTrashed = project.status == TaskStatus.trashed;
    final isCompleted = project.status == TaskStatus.completedActive;

    if (direction == DismissDirection.startToEnd) {
      // 右滑（左侧操作）
      if (isActive) {
        // 活跃项目：归档
        final confirmed = await _confirmProjectArchive(context, ref, project);
        if (confirmed == null || confirmed == false) {
          return false;
        }
        await _archiveProject(context, ref, project.id, archiveTasks: confirmed == true);
        return true;
      } else if (isArchived || isCompleted) {
        // 归档/完成项目：移入回收站
        final confirmed = await _confirmProjectTrash(context, project);
        if (!confirmed) {
          return false;
        }
        await _trashProject(context, ref, project.id);
        return true;
      } else if (isTrashed) {
        // 回收站：删除
        final confirmed = await _confirmProjectDelete(context, project);
        if (!confirmed) {
          return false;
        }
        await _deleteProject(context, ref, project.id);
        return true;
      }
    } else if (direction == DismissDirection.endToStart) {
      // 左滑（右侧操作）
      if (isActive) {
        // 活跃项目：完成
        final confirmed = await _confirmProjectComplete(context, ref, project);
        if (confirmed == null || confirmed == false) {
          return false;
        }
        await _completeProject(context, ref, project.id, archiveTasks: confirmed == true);
        return true;
      } else if (isArchived || isCompleted) {
        // 归档/完成项目：重启
        await _reactivateProject(context, ref, project.id);
        return true;
      } else if (isTrashed) {
        // 回收站：重启
        await _restoreProject(context, ref, project.id);
        return true;
      }
    }

    return false;
  }

  Future<bool?> _confirmProjectArchive(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasActiveTasks = await ref
        .read(projectServiceProvider)
        .hasActiveTasks(project.projectId);

    if (!hasActiveTasks) {
      // 没有活跃任务，直接确认
      return true;
    }

    // 有活跃任务，弹出确认对话框询问是否归档活跃任务
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectArchiveConfirmTitle),
        content: const Text(
          '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('仅归档项目'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('归档项目及活跃任务'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool?> _confirmProjectComplete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasActiveTasks = await ref
        .read(projectServiceProvider)
        .hasActiveTasks(project.projectId);

    if (!hasActiveTasks) {
      // 没有活跃任务，直接确认
      return true;
    }

    // 有活跃任务，弹出确认对话框询问是否归档活跃任务
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完成项目'),
        content: const Text(
          '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('仅完成项目'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('完成项目并归档活跃任务'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _archiveProject(
    BuildContext context,
    WidgetRef ref,
    int projectId, {
    bool archiveTasks = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(projectServiceProvider)
          .archiveProject(projectId, archiveActiveTasks: archiveTasks);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedToast)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to archive project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedError)),
      );
    }
  }

  Future<void> _completeProject(
    BuildContext context,
    WidgetRef ref,
    int projectId, {
    bool archiveTasks = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(projectServiceProvider)
          .completeProject(projectId, archiveActiveTasks: archiveTasks);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.actionMarkCompleted)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to complete project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskCompletedError)),
      );
    }
  }

  Future<void> _trashProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).trashProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.actionMoveToTrash)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to trash project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedError)),
      );
    }
  }

  Future<void> _restoreProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).restoreProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreSuccess)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to restore project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreError)),
      );
    }
  }

  Future<void> _reactivateProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).reactivateProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreSuccess)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reactivate project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreError)),
      );
    }
  }

  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).deleteProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('项目已永久删除')),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to delete project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreError)),
      );
    }
  }

  Future<bool> _confirmProjectTrash(
    BuildContext context,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('移到回收站'),
        content: const Text(
          '确定要删除这个项目吗？项目将被移到回收站，30天后永久删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionMoveToTrash),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _confirmProjectDelete(
    BuildContext context,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('永久删除'),
        content: const Text(
          '确定要永久删除这个项目吗？此操作无法撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashPermanentDeleteAction),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class ProjectDetails extends ConsumerWidget {
  const ProjectDetails({
    super.key,
    required this.project,
    required this.milestones,
  });

  final Project project;
  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (milestones.isEmpty)
          EmptyPlaceholder(message: l10n.projectNoMilestonesHint)
        else
          ...milestones.map<Widget>(
            (milestone) => MilestoneCard(milestone: milestone),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _addMilestone(context, ref),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('添加里程碑'),
        ),
      ],
    );
  }

  Future<void> _addMilestone(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => MilestoneEditSheet(
        projectId: project.projectId,
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('里程碑已添加')),
      );
    }
  }
}

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
        final confirmed = await _confirmProjectComplete(context, ref, project);
        if (confirmed != null) {
          await _completeProject(
            context,
            ref,
            project.id,
            archiveTasks: confirmed == true,
          );
        }
        break;
      case 'archive':
        final confirmed = await _confirmProjectArchive(context, ref, project);
        if (confirmed != null) {
          await _archiveProject(
            context,
            ref,
            project.id,
            archiveTasks: confirmed == true,
          );
        }
        break;
      case 'trash':
        await _trashProject(context, ref, project.id);
        break;
      case 'restore':
        await _restoreProject(context, ref, project.id);
        break;
    }
  }

  Future<void> _trashProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).trashProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.actionMoveToTrash)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to trash project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedError)),
      );
    }
  }

  Future<void> _restoreProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).restoreProject(projectId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreSuccess)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to restore project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoreError)),
      );
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

  Future<bool?> _confirmProjectArchive(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasActiveTasks = await ref
        .read(projectServiceProvider)
        .hasActiveTasks(project.projectId);

    if (!hasActiveTasks) {
      // 没有活跃任务，直接确认
      return true;
    }

    // 有活跃任务，弹出确认对话框询问是否归档活跃任务
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectArchiveConfirmTitle),
        content: const Text(
          '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('仅归档项目'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('归档项目及活跃任务'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool?> _confirmProjectComplete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasActiveTasks = await ref
        .read(projectServiceProvider)
        .hasActiveTasks(project.projectId);

    if (!hasActiveTasks) {
      // 没有活跃任务，直接确认
      return true;
    }

    // 有活跃任务，弹出确认对话框询问是否归档活跃任务
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完成项目'),
        content: const Text(
          '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('仅完成项目'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('完成项目并归档活跃任务'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _archiveProject(
    BuildContext context,
    WidgetRef ref,
    int projectId, {
    bool archiveTasks = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(projectServiceProvider)
          .archiveProject(projectId, archiveActiveTasks: archiveTasks);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedToast)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to archive project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedError)),
      );
    }
  }

  Future<void> _completeProject(
    BuildContext context,
    WidgetRef ref,
    int projectId, {
    bool archiveTasks = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(projectServiceProvider)
          .completeProject(projectId, archiveActiveTasks: archiveTasks);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.actionMarkCompleted)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to complete project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskCompletedError)),
      );
    }
  }
}

class ProjectProgressBar extends StatelessWidget {
  const ProjectProgressBar({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    required this.overdue,
  });

  final double progress;
  final int completed;
  final int total;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: total == 0 ? 0 : progress,
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            overdue ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? l10n.projectProgressEmpty
              : l10n.projectProgressLabel(percentage, completed, total),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
