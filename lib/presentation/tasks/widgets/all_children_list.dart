import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/task_status_utils.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 显示父任务的所有子任务列表（不可编辑）
/// 
/// 显示内容：
/// - 标题
/// - 截止日期（如果有）
/// - 任务状态
/// 
/// 只显示一级，不递归
/// 过滤 trashed 状态（双重保障）
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
    final childrenAsync = ref.watch(parentTaskChildrenProvider(parentTaskId));
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
    final statusText = getTaskStatusDisplayText(task.status, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 任务标题
          Expanded(
            child: Text(
              task.title,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 截止日期（如果有）
          if (task.dueAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatDueDate(task.dueAt!, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          // 任务状态
          if (statusText.isNotEmpty)
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
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
}

/// Provider: 获取父任务的所有子任务（排除 trashed）
final parentTaskChildrenProvider =
    FutureProvider.family<List<Task>, int>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return taskRepository.listChildren(parentId);
});

