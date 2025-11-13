import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/pinned_task_provider.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'compact_circular_timer_widget.dart';
import 'dismissible_task_tile.dart';
import 'swipe_action_handler.dart';
import 'swipe_configs.dart';
import 'timeout_warning_widget.dart';
import 'utils/task_bottom_sheet_helper.dart';

/// 置顶任务栏组件
/// 
/// 显示置顶的任务标题、计时器和超时警告
/// 支持点击打开弹窗、左滑右滑操作
class PinnedTaskBar extends ConsumerWidget {
  const PinnedTaskBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedTaskId = ref.watch(pinnedTaskIdProvider);

    // 如果没有置顶任务，不显示
    if (pinnedTaskId == null) {
      return const SizedBox.shrink();
    }

    // 监听任务数据
    final taskAsync = ref.watch(taskByIdProvider(pinnedTaskId));

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
      child: taskAsync.when(
        data: (task) {
          // 如果任务不存在或状态为 completedActive/trashed/archived，自动清除置顶
          if (task == null ||
              task.status == TaskStatus.completedActive ||
              task.status == TaskStatus.trashed ||
              task.status == TaskStatus.archived) {
            // 使用 WidgetsBinding.instance.addPostFrameCallback 清除置顶
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ref.read(pinnedTaskIdProvider) == pinnedTaskId) {
                ref.read(pinnedTaskIdProvider.notifier).setPinnedTaskId(null);
              }
            });
            return const SizedBox.shrink(key: ValueKey('empty'));
          }

          // 显示置顶任务栏内容
          return _PinnedTaskBarContent(
            key: ValueKey(pinnedTaskId),
            task: task,
          );
        },
        loading: () => const SizedBox.shrink(key: ValueKey('loading')),
        error: (_, __) {
          // 错误时清除置顶
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(pinnedTaskIdProvider) == pinnedTaskId) {
              ref.read(pinnedTaskIdProvider.notifier).setPinnedTaskId(null);
            }
          });
          return const SizedBox.shrink(key: ValueKey('error'));
        },
      ),
    );
  }
}

/// 置顶任务栏内容组件
class _PinnedTaskBarContent extends ConsumerWidget {
  const _PinnedTaskBarContent({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 获取反色主题颜色
    final inverseSurface = theme.colorScheme.inverseSurface;
    final onInverseSurface = theme.colorScheme.onInverseSurface;

    // 外层容器：固定圆角和阴影，不参与滑动
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: inverseSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // 使用 ClipRRect 确保滑动内容不超出圆角边界
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DismissibleTaskTile(
          task: task,
          config: SwipeConfigs.tasksConfig,
          onLeftAction: (task) async {
            // 左滑：完成任务
            await SwipeActionHandler.handleAction(
              context,
              ref,
              SwipeConfigs.tasksConfig.leftAction,
              task,
            );
            // 完成任务后，置顶会自动清除（通过任务状态监听）
          },
          onRightAction: (task) async {
            // 右滑：归档任务
            await SwipeActionHandler.handleAction(
              context,
              ref,
              SwipeConfigs.tasksConfig.rightAction,
              task,
            );
            // 归档任务后，置顶会自动清除（通过任务状态监听）
          },
          child: InkWell(
            onTap: () {
              // 点击任务标题打开弹窗
              TaskBottomSheetHelper.showTaskBottomSheet(
                context,
                ref,
                task,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 左侧：计时器
                  CompactCircularTimerWidget(task: task),
                  const SizedBox(width: 12),
                  // 右侧：任务标题和超时警告
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 任务标题（最多3行）
                        Text(
                          task.title.isEmpty 
                              ? AppLocalizations.of(context).taskTitleHint 
                              : task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: onInverseSurface,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 超时警告（条件显示）
                        TimeoutWarningWidget(task: task),
                      ],
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

