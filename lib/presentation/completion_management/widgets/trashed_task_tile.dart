import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_action_type.dart';
import '../../../core/providers/app_providers.dart';
import '../../tasks/utils/tag_utils.dart';
import '../../widgets/inline_project_milestone_display.dart';
import 'completion_time_display.dart';

/// 回收站任务 Tile 组件
/// 
/// 特性：
/// - 不显示拖拽手柄（无拖拽功能）
/// - 显示删除时间（使用 updatedAt 作为删除时间的近似值）
/// - 支持滑动操作：右滑恢复，左滑永久删除
class TrashedTaskTile extends ConsumerWidget {
  const TrashedTaskTile({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 构建任务内容
    final taskContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：标题
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    // 回收站任务通常使用较暗的样式
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 第二行：标签 + 项目/里程碑 + 删除时间
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // 已选中的标签（只显示，不可编辑）
              ...task.tags.map((slug) {
                final tagWidget = buildModernTag(context, slug);
                return tagWidget ?? const SizedBox.shrink();
              }),
              // 项目/里程碑信息（只读）
              _buildProjectMilestoneDisplay(context, ref),
              // 删除时间显示（绝对格式，使用 updatedAt 作为删除时间的近似值）
              CompletionTimeDisplay(
                dateTime: task.updatedAt,
                format: TimeDisplayFormat.absolute,
              ),
            ],
          ),
        ),
      ],
    );

    // 使用 DismissibleTaskTile 包裹，支持滑动操作
    return DismissibleTaskTile(
      task: task,
      config: SwipeConfigs.trashConfig,
      onLeftAction: (task) {
        // 右滑：恢复任务
        SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.restore,
          task,
        );
      },
      onRightAction: (task) {
        // 左滑：永久删除
        SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.permanentDelete,
          task,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: taskContent,
      ),
    );
  }

  /// 构建项目/里程碑显示（只读）
  Widget _buildProjectMilestoneDisplay(BuildContext context, WidgetRef ref) {
    final hierarchyAsync = ref.watch(taskProjectHierarchyProvider(task.id));
    
    return hierarchyAsync.when(
      data: (hierarchy) {
        if (hierarchy == null) {
          return const SizedBox.shrink();
        }
        return InlineProjectMilestoneDisplay(
          project: hierarchy.project,
          milestone: hierarchy.milestone,
          readOnly: true,
          onSelected: (_) {}, // 只读模式，不需要处理选择
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

