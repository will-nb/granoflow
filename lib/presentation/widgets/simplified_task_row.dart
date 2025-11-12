import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'utils/task_bottom_sheet_helper.dart';
import 'utils/task_status_toggle_helper.dart';

/// 简化的任务行组件
/// 
/// 显示 Checkbox 和任务标题
/// 点击 Checkbox 切换任务完成状态
/// 点击任务根据状态显示操作弹窗或详情弹窗
class SimplifiedTaskRow extends ConsumerWidget {
  const SimplifiedTaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.section,
  });

  final Task task;
  final VoidCallback? onTap;
  final TaskSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompleted = task.status == TaskStatus.completedActive;
    final isTrashed = task.status == TaskStatus.trashed;
    final showStrikethrough = isCompleted && section == TaskSection.today;

    return Container(
      width: double.infinity,
      child: Semantics(
        label: '${l10n.taskListTaskStatusLabel}: ${task.title}',
        hint: isCompleted
            ? l10n.taskListTaskStatusCompletedHint
            : l10n.taskListTaskStatusUncompletedHint,
        button: true,
        child: InkWell(
          onTap: onTap ?? () {
            // 根据任务状态显示不同的弹窗
            TaskBottomSheetHelper.showTaskBottomSheet(context, ref, task);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            child: Row(
              children: [
                // Checkbox：点击区域扩展到 40dp × 40dp
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      TaskStatusToggleHelper.toggleTaskStatus(
                        context,
                        ref,
                        task,
                        section: section,
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    checkColor: theme.colorScheme.onPrimary,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.primary;
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: isTrashed
                          ? theme.colorScheme.onSurface
                              .withValues(alpha: 0.45)
                          : (showStrikethrough
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)
                              : null),
                      decoration: showStrikethrough
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
