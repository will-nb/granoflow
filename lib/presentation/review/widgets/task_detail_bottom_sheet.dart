import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/task_hierarchy_providers.dart';
import '../../../core/services/tag_service.dart';
import '../../../data/models/task.dart';
import '../../tasks/utils/date_utils.dart';
import '../../widgets/inline_project_milestone_display.dart';
import '../../widgets/modern_tag.dart';

/// 任务详情底部弹窗
/// 
/// 显示任务的完整信息：标题、标签、项目/里程碑、截止日期
/// 支持手势关闭和滚动
class TaskDetailBottomSheet extends ConsumerWidget {
  const TaskDetailBottomSheet({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // 获取项目/里程碑信息
    final hierarchyAsync = ref.watch(
      taskProjectHierarchyProvider(task.id),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示器
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 任务标题（完整显示，不截断）
                  Text(
                    task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标签
                  if (task.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tags.map((slug) {
                        final tagData = TagService.getTagData(context, slug);
                        if (tagData == null) {
                          return const SizedBox.shrink();
                        }
                        return ModernTag(
                          label: tagData.label,
                          color: tagData.color,
                          icon: tagData.icon,
                          prefix: tagData.prefix,
                          selected: true,
                          variant: TagVariant.minimal,
                          size: TagSize.small,
                          showCheckmark: false,
                          onTap: null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 项目/里程碑
                  hierarchyAsync.when(
                    data: (hierarchy) {
                      if (hierarchy != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InlineProjectMilestoneDisplay(
                            project: hierarchy.project,
                            milestone: hierarchy.milestone,
                            onSelected: (_) {}, // 只读模式，不处理选择
                            readOnly: true,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  // 截止日期
                  if (task.dueAt != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDeadline(context, task.dueAt) ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

