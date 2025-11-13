import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/task_query_providers.dart';
import '../../../core/utils/task_status_utils.dart';
import '../../../data/models/project.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/date_utils.dart';
import '../../widgets/modern_tag.dart';
import '../../../core/services/tag_service.dart';

/// 项目详情底部弹窗
///
/// 显示项目的完整信息（只读）
/// 支持手势关闭和滚动
class ProjectDetailBottomSheet extends ConsumerWidget {
  const ProjectDetailBottomSheet({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 获取项目里程碑数量
    final milestonesAsync = ref.watch(projectMilestonesDomainProvider(project.id));

    // 获取项目任务统计
    final statisticsAsync = ref.watch(projectTasksStatisticsProvider(project.id));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示器
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 项目标题
                  Text(
                    project.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 项目描述
                  if (project.description != null && project.description!.isNotEmpty) ...[
                    Text(
                      project.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 截止日期
                  if (project.dueAt != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDeadline(context, project.dueAt) ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 项目状态
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getTaskStatusDisplayText(project.status, l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 标签
                  if (project.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.tags.map((slug) {
                        final tagData = TagService.getTagData(context, slug);
                        if (tagData == null) {
                          return const SizedBox.shrink();
                        }
                        return ModernTag(
                          label: tagData.label,
                          color: tagData.color,
                          icon: tagData.icon,
                          prefix: tagData.prefix,
                          selected: true,
                          variant: TagVariant.minimal,
                          size: TagSize.small,
                          showCheckmark: false,
                          onTap: null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 创建时间
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.detailCreated(_formatDateTime(context, project.createdAt)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 更新时间
                  Row(
                    children: [
                      Icon(
                        Icons.update_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.detailUpdated(_formatDateTime(context, project.updatedAt)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 里程碑数量统计
                  milestonesAsync.when(
                    data: (milestones) {
                      return Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.detailMilestones(milestones.length),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // 任务统计
                  statisticsAsync.when(
                    data: (statistics) {
                      return Row(
                        children: [
                          Icon(
                            Icons.task_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.detailTasks(
                              statistics.completedCount,
                              statistics.totalCount,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  // 编辑链接
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/projects');
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.actionEdit),
                  ),
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context);
    final formatter = DateFormat.yMMMd(locale.toString()).add_Hm();
    return formatter.format(dateTime);
  }
}

/// 显示项目详情弹窗
void showProjectDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ProjectDetailBottomSheet(
      project: project,
    ),
  );
}

