import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/tag_service.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

/// 任务开始计时按钮组件
/// 风格与标签和截止日期编辑器一致，用于选择计时标签
class TaskStartTimerButton extends ConsumerWidget {
  const TaskStartTimerButton({
    super.key,
    required this.task,
  });

  final Task task;

  Future<void> _selectTimedTag(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final taskService = ref.read(taskServiceProvider);

    try {
      // 检查是否是同组标签，如果是则先删除同组的旧标签
      String? tagToRemove;
      for (final existingTag in task.tags) {
        if (TagService.areInSameGroup('timed', existingTag)) {
          tagToRemove = existingTag;
          break;
        }
      }

      // 构建新的标签列表
      List<String> updatedTags = List.from(task.tags);

      // 先删除同组标签（执行方式标签互斥）
      if (tagToRemove != null && tagToRemove.isNotEmpty) {
        updatedTags = updatedTags.where((t) => t != tagToRemove).toList();
      }

      // 添加计时标签（确保使用规范化后的 slug）
      final normalizedSlug = TagService.normalizeSlug('timed');
      updatedTags.add(normalizedSlug);

      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(tags: updatedTags),
      );
    } catch (e) {
      debugPrint('Failed to select timed tag: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.taskStartTimerError}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return InkWell(
      onTap: () => _selectTimedTag(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).taskStartTimerTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

