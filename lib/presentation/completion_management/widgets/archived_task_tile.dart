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

/// 已归档任务 Tile 组件
/// 
/// 特性：
/// - 不显示拖拽手柄（无拖拽功能）
/// - 显示归档时间（archivedAt）而不是截止日期（dueAt）
/// - 支持滑动操作：右滑加入今日，左滑移动到回收站
/// - 支持展开/收缩显示子任务
class ArchivedTaskTile extends ConsumerWidget {
  const ArchivedTaskTile({
    super.key,
    required this.task,
    this.depth = 0,
  });

  final Task task;
  final int depth; // 任务层级深度（用于缩进显示）

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // 层级功能已移除，不再显示子任务

    // 构建任务内容
    final taskContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：标题 + 展开/收缩按钮
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩进（子任务有缩进）
            if (depth > 0)
              SizedBox(width: depth * 16.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    // 归档任务通常不需要删除线样式
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 层级功能已移除，不再显示展开/收缩按钮
          ],
        ),
        // 第二行：标签 + 项目/里程碑 + 归档时间
        Padding(
          padding: EdgeInsets.only(top: 8, left: depth * 16.0),
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
              // 归档时间显示（绝对格式，替代截止日期）
              CompletionTimeDisplay(
                dateTime: task.archivedAt,
                format: TimeDisplayFormat.absolute,
              ),
            ],
          ),
        ),
        // 层级功能已移除，不再显示子任务列表
      ],
    );

    // 使用 DismissibleTaskTile 包裹，支持滑动操作
    return DismissibleTaskTile(
      task: task,
      config: SwipeConfigs.completedArchivedConfig,
      onLeftAction: (task) {
        // 右滑：加入今日任务
        SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.quickPlan,
          task,
        );
      },
      onRightAction: (task) {
        // 左滑：移动到回收站
        SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.delete,
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

