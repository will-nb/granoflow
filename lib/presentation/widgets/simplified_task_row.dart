import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'utils/task_bottom_sheet_helper.dart';
import 'utils/task_status_toggle_helper.dart';

/// 简化的任务行组件
/// 
/// 显示任务标题，可选显示 Checkbox
/// 点击 Checkbox 切换任务完成状态
/// 点击任务根据状态显示操作弹窗或详情弹窗
class SimplifiedTaskRow extends ConsumerWidget {
  const SimplifiedTaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.section,
    this.showCheckbox = false,
    this.verticalPadding = 12.0,
  });

  final Task task;
  final VoidCallback? onTap;
  final TaskSection? section;
  final bool showCheckbox;
  final double verticalPadding;

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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {
              // 根据任务状态显示不同的弹窗
              TaskBottomSheetHelper.showTaskBottomSheet(context, ref, task);
            },
            // 不拦截长按事件，让 ReorderableDragStartListener 能够接收
            // 设置 onLongPress 为 null 可以防止 InkWell 拦截长按事件
            onLongPress: null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: verticalPadding),
              child: Row(
                children: [
                  // Checkbox：只在 showCheckbox 为 true 时显示
                  if (showCheckbox) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                ],
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
      ),
    );
  }
}
