import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _startClockTimer(BuildContext context, WidgetRef ref) async {
    // 导航到计时器页面
    context.push('/clock/${task.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return InkWell(
      onTap: () => _startClockTimer(context, ref),
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

