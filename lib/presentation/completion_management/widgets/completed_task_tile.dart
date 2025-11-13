import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_action_type.dart';
import '../../../core/providers/app_providers.dart';
import '../../widgets/inline_project_milestone_display.dart';
import '../../widgets/modern_tag.dart';
import '../../../core/services/tag_service.dart';
import 'completion_time_display.dart';

/// 已完成任务 Tile 组件
/// 
/// 特性：
/// - 不显示拖拽手柄（无拖拽功能）
/// - 显示完成时间（endedAt）而不是截止日期（dueAt）
/// - 支持滑动操作：右滑加入今日，左滑移动到回收站
/// - 支持展开/收缩显示子任务
class CompletedTaskTile extends ConsumerWidget {
  const CompletedTaskTile({
    super.key,
    required this.task,
    this.depth = 0,
  });

  final Task task;
  final int depth; // 任务层级深度（用于缩进显示）

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskStatus.completedActive;
    
    // 层级功能已移除，不再显示子任务
    final hasChildren = false;
    final isExpanded = false;

    // 构建任务内容，使用简化的 TaskRowContent，但替换完成时间显示
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
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 层级功能已移除，不再显示展开/收缩按钮
          ],
        ),
        // 第二行：标签 + 项目/里程碑 + 完成时间
        Padding(
          padding: EdgeInsets.only(top: 8, left: depth * 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // 已选中的标签（只显示，不可编辑，使用与Tasks页面一致的样式）
              ...task.tags.map((slug) {
                // 使用 TagService 统一处理，自动兼容旧数据（带前缀的 slug）
                final tagData = TagService.getTagData(context, slug);
                if (tagData == null) {
                  return const SizedBox.shrink(); // 无效标签不显示
                }
                // 使用 ModernTag 并传入与 InlineEditableTag 相同的参数（variant: minimal, size: small）
                // 这样样式与 Tasks 页面完全一致
                return ModernTag(
                  label: tagData.label,
                  color: tagData.color,
                  icon: tagData.icon,
                  prefix: tagData.prefix,
                  selected: true,
                  variant: TagVariant.minimal, // 与 InlineEditableTag 一致
                  size: TagSize.small, // 与 InlineEditableTag 一致
                  showCheckmark: false, // 不显示对勾（与 InlineEditableTag 一致）
                  onTap: null, // 只读模式，不响应点击
                );
              }),
              // 项目/里程碑信息（只读）
              _buildProjectMilestoneDisplay(context, ref),
              // 完成时间显示（绝对格式，替代截止日期）
              CompletionTimeDisplay(
                dateTime: task.endedAt,
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

