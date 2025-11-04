import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/project.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../widgets/description_block.dart';
import '../widgets/error_banner.dart';
import '../widgets/project_swipe_background.dart';
import 'widgets/project_header_row.dart';
import 'widgets/project_details.dart';
import 'widgets/project_progress_bar.dart';
import 'widgets/project_card_swipe_config.dart';

/// 项目卡片组件
/// 
/// 显示项目信息，支持滑动操作、展开/收起、查看里程碑等
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

    final swipeConfig = getProjectSwipeConfig(project, theme, l10n);

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
          return await handleProjectSwipeAction(
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
                    ProjectHeaderRow(
                      project: project,
                      isExpanded: isExpanded,
                    ),
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
                    ProjectHeaderRow(
                      project: project,
                      isExpanded: isExpanded,
                    ),
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
}
