import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'utils/task_bottom_sheet_helper.dart';

/// 简化的任务行组件
/// 
/// 只显示任务标题
/// 点击任务根据状态显示操作弹窗或详情弹窗
class SimplifiedTaskRow extends ConsumerWidget {
  const SimplifiedTaskRow({
    super.key,
    required this.task,
    this.onTap,
  });

  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompleted = task.status == TaskStatus.completedActive;
    final isTrashed = task.status == TaskStatus.trashed;

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
            child: Text(
              task.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: isTrashed
                    ? theme.colorScheme.onSurface
                        .withValues(alpha: 0.45)
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
