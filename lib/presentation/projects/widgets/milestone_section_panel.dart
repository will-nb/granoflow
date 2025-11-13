import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/task_query_providers.dart';
import '../../../core/theme/app_spacing_tokens.dart';
import '../../../data/models/milestone.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/widgets/empty_section_hint.dart';
import '../../widgets/error_banner.dart';
import 'milestone_task_list_simplified.dart';
import 'milestone_detail_bottom_sheet.dart';

/// 里程碑分区面板组件
///
/// 显示里程碑标题、进度和任务列表
/// 支持拖拽排序（里程碑内和跨里程碑）
class MilestoneSectionPanel extends ConsumerWidget {
  const MilestoneSectionPanel({
    super.key,
    required this.milestone,
    this.tasks,
    this.onQuickAdd,
  });

  final Milestone milestone;
  final List<Task>? tasks;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = tasks != null
        ? AsyncValue<List<Task>>.data(tasks!)
        : ref.watch(milestoneTasksProvider(milestone.id));
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final spacing = Theme.of(context).extension<AppSpacingTokens>();
    final spacingTokens = spacing ?? AppSpacingTokens.light;

    // 获取里程碑任务统计
    final statisticsAsync = ref.watch(milestoneTasksStatisticsProvider(milestone.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacingTokens.cardHorizontalPadding,
          vertical: spacingTokens.cardVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分区标题区域
            Row(
              children: [
                // 里程碑标题（可点击，显示里程碑详情弹窗）
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showMilestoneDetailBottomSheet(context, ref, milestone);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              milestone.title,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 快速添加按钮
                if (onQuickAdd != null)
                  IconButton(
                    onPressed: onQuickAdd,
                    icon: const Icon(Icons.add_task_outlined),
                    tooltip: l10n.taskListQuickAddTooltip,
                  ),
              ],
            ),
            // 里程碑进度指示器
            statisticsAsync.when(
              data: (statistics) {
                if (statistics.totalCount == 0) {
                  return const SizedBox.shrink();
                }
                final percentage = (statistics.progress * 100).clamp(0, 100).toInt();
                final overdue = milestone.dueAt != null &&
                    milestone.dueAt!.isBefore(DateTime.now());
                final theme = Theme.of(context);

                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
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
                            minHeight: 4,
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
                      const SizedBox(height: 4),
                      // 进度文字
                      Text(
                        l10n.milestoneProgressLabel(
                          statistics.completedCount,
                          statistics.totalCount,
                          percentage,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(height: spacingTokens.sectionInternalSpacing),
            // 任务列表区域
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                return MilestoneTaskListSimplified(
                  milestoneId: milestone.id,
                  tasks: tasks,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => ErrorBanner(
                message: l10n.milestonesLoadError('$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

