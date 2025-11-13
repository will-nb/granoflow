import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/task_query_providers.dart';
import '../../../core/utils/task_status_utils.dart';
import '../../../data/models/project.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/date_utils.dart';
import '../../widgets/error_banner.dart';
import 'project_detail_bottom_sheet.dart';

/// 项目信息头部组件
///
/// 显示项目标题、基本信息和进度可视化
class ProjectInfoHeader extends ConsumerWidget {
  const ProjectInfoHeader({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 获取项目任务统计
    final statisticsAsync = ref.watch(projectTasksStatisticsProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目标题（可点击，显示项目详情弹窗）
        InkWell(
          onTap: () {
            showProjectDetailBottomSheet(context, ref, project);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 项目基本信息
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            // 截止日期
            if (project.dueAt != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDeadline(context, project.dueAt) ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            // 项目状态
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  getTaskStatusDisplayText(project.status, l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 项目进度可视化
        statisticsAsync.when(
          data: (statistics) {
            if (statistics.totalCount == 0) {
              return Text(
                l10n.projectNoTasks,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }

            final percentage = (statistics.progress * 100).clamp(0, 100).toInt();
            final overdue = project.dueAt != null &&
                project.dueAt!.isBefore(DateTime.now());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 进度条
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: statistics.progress,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // 进度文字
                Text(
                  l10n.projectProgressTasksLabel(
                    statistics.completedCount,
                    statistics.totalCount,
                    percentage,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
          loading: () => LinearProgressIndicator(
            color: theme.colorScheme.primary,
            minHeight: 2,
          ),
          error: (error, stackTrace) => ErrorBanner(
            message: l10n.projectProgressLoadError('$error'),
          ),
        ),
      ],
    );
  }
}

