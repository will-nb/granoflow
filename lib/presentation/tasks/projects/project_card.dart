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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey('project-${project.id}'),
        direction: DismissDirection.horizontal,
        background: projectSwipeBackground(
          color: theme.colorScheme.primary,
          icon: Icons.archive_outlined,
          label: l10n.taskArchiveAction,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: projectSwipeBackground(
          color: theme.colorScheme.tertiary,
          icon: Icons.snooze,
          label: l10n.projectSnoozeAction,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            final confirmed = await _confirmProjectArchive(context, project);
            if (!confirmed) {
              return false;
            }
            await _archiveProject(context, ref, project.id);
            return true;
          }

          final confirmed = await _confirmProjectSnooze(context, project);
          if (!confirmed) {
            return false;
          }
          await _snoozeProject(context, ref, project);
          return false;
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

  Future<bool> _confirmProjectArchive(
    BuildContext context,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectArchiveConfirmTitle),
        content: Text(l10n.projectArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.taskArchiveAction),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _confirmProjectSnooze(
    BuildContext context,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectSnoozeConfirmTitle),
        content: Text(l10n.projectSnoozeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.projectSnoozeConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _archiveProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectServiceProvider).archiveProject(projectId);
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

  Future<void> _snoozeProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(projectServiceProvider).snoozeProject(project.id);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.projectSnoozeSuccess)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to snooze project: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.projectSnoozeError)));
    }
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
    if (milestones.isEmpty) {
      return EmptyPlaceholder(message: l10n.projectNoMilestonesHint);
    }
    return Column(
      children: milestones
          .map<Widget>((milestone) => MilestoneCard(milestone: milestone))
          .toList(growable: false),
    );
  }
}

class ProjectHeaderRow extends StatelessWidget {
  const ProjectHeaderRow({
    super.key,
    required this.project,
    required this.isExpanded,
  });

  final Project project;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
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
              child: Text(project.title, style: theme.textTheme.titleLarge),
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
