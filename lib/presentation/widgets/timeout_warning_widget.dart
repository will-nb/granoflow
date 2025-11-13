import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/focus_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

/// 超时警告提示组件
/// 
/// 当任务计时超过1小时时显示警告提示
class TimeoutWarningWidget extends ConsumerWidget {
  const TimeoutWarningWidget({
    super.key,
    required this.task,
  });

  final Task task;

  /// 计算已用时间
  Duration _computeElapsed(FocusSession session) {
    final taskStatus = task.status;
    
    if (taskStatus == TaskStatus.paused) {
      // 暂停状态：使用已保存的时间
      return Duration(minutes: session.actualMinutes);
    } else {
      // doing状态：实时计算（now - session.startedAt）
      final now = DateTime.now();
      return now.difference(session.startedAt);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sessionAsync = ref.watch(focusSessionProvider(task.id));

    return sessionAsync.when(
      data: (session) {
        // 如果没有活跃session，不显示
        if (session == null || !session.isActive) {
          return const SizedBox.shrink();
        }

        // 计算已用时间
        final elapsed = _computeElapsed(session);
        final elapsedHours = elapsed.inHours;

        // 如果已用时间小于1小时，不显示
        if (elapsedHours < 1) {
          return const SizedBox.shrink();
        }

        // 显示警告提示
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(elapsedHours),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.taskTimeoutWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

