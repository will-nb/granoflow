import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/task_section_utils.dart';
import '../../../core/utils/task_status_utils.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// 显示父任务的所有子任务列表（不可编辑）
/// 
/// 显示内容：
/// - 标题
/// - 截止日期（如果有）
/// - 任务状态
/// - 删除时间（如果是 trashed 状态）
/// 
/// 只显示一级，不递归
/// 包含 trashed 状态的子任务（用于显示已删除的子任务）
class AllChildrenList extends ConsumerWidget {
  const AllChildrenList({
    super.key,
    required this.parentTaskId,
    required this.currentSection,
  });

  final int parentTaskId;
  final TaskSection currentSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(
      parentTaskChildrenIncludingTrashedProvider(parentTaskId),
    );
    final theme = Theme.of(context);

    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) {
              return _ChildTaskItem(
                task: child,
                currentSection: currentSection,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 子任务项组件
class _ChildTaskItem extends ConsumerWidget {
  const _ChildTaskItem({
    required this.task,
    required this.currentSection,
  });

  final Task task;
  final TaskSection currentSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isTrashed = task.status == TaskStatus.trashed;
    final statusText = isTrashed ? null : getTaskStatusDisplayText(task.status, l10n);

    return InkWell(
      onTap: () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务标题
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isTrashed
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                          : null,
                      decoration: isTrashed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // 截止日期（如果有且不是 trashed 状态）
                if (task.dueAt != null && !isTrashed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatDueDate(task.dueAt!, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                // 任务状态（非 trashed 状态）
                if (statusText != null && statusText.isNotEmpty)
                  Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            // 删除时间（如果是 trashed 状态）
            if (isTrashed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatDeletedTime(task.updatedAt, l10n, context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);

    if (dueDate == today) {
      return l10n.plannerSectionTodayTitle;
    } else if (dueDate == today.add(const Duration(days: 1))) {
      return l10n.plannerSectionTomorrowTitle;
    } else {
      return '${dueDate.year}/${dueDate.month}/${dueDate.day}';
    }
  }

  /// 格式化删除时间（年月日时分，不显示秒）
  String _formatDeletedTime(
    DateTime deletedAt,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context);
    // 格式：年月日 时分（不显示秒）
    // 中文格式：2025年11月3日 14:30
    // 英文格式：Nov 3, 2025 14:30
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_Hm();
    return dateFormat.format(deletedAt);
  }

  void _handleTap(BuildContext context) {
    switch (task.status) {
      case TaskStatus.inbox:
        context.go('/inbox');
        return;
      case TaskStatus.pending:
        final section = _locateSectionForTask(task);
        context.go('/tasks${section != null ? '?section=$section' : ''}');
        return;
      case TaskStatus.doing:
        final section2 = _locateSectionForTask(task);
        context.go('/tasks${section2 != null ? '?section=$section2' : ''}');
        return;
      case TaskStatus.completedActive:
      case TaskStatus.archived:
      case TaskStatus.trashed:
      case TaskStatus.pseudoDeleted:
        context.go('/tasks');
        return;
    }
  }

  /// 基于任务状态与截止日期，推断其所在的任务分区（用于跳转定位）
  /// 返回的字符串需与 TaskListPage._parseSection 对应
  /// 使用 TaskSectionUtils 统一边界定义（严禁修改）
  String? _locateSectionForTask(Task task) {
    // 使用 TaskSectionUtils 统一边界定义
    final section = TaskSectionUtils.getSectionForDate(task.dueAt);
    
    // 转换为字符串（TaskSection enum 的 name 属性）
    switch (section) {
      case TaskSection.overdue:
        return 'overdue';
      case TaskSection.today:
        return 'today';
      case TaskSection.tomorrow:
        return 'tomorrow';
      case TaskSection.thisWeek:
        return 'thisWeek';
      case TaskSection.thisMonth:
        return 'thisMonth';
      case TaskSection.nextMonth:
        return 'nextMonth';
      case TaskSection.later:
        return 'later';
      default:
        return null;
    }
  }
}

/// Provider: 获取父任务的所有子任务（排除 trashed）
final parentTaskChildrenProvider =
    FutureProvider.family<List<Task>, int>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return taskRepository.listChildren(parentId);
});

/// Provider: 获取父任务的所有子任务（包括 trashed 状态）
/// 用于在父任务展开时显示已删除的子任务
final parentTaskChildrenIncludingTrashedProvider =
    FutureProvider.family<List<Task>, int>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return taskRepository.listChildrenIncludingTrashed(parentId);
});

