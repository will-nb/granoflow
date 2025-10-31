import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import 'project_milestone_text_utils.dart';
import 'project_milestone_picker.dart';

/// 可内联编辑的项目/里程碑显示组件
/// 风格与 InlineDeadlineEditor 和 InlineEditableTag 一致（Minimal 风格）
class InlineProjectMilestoneDisplay extends ConsumerWidget {
  const InlineProjectMilestoneDisplay({
    super.key,
    required this.project,
    this.milestone,
    required this.onSelected,
    this.currentParentId,
    this.showIcon = true,
  });

  final Task project;
  final Task? milestone;
  final ValueChanged<int?> onSelected;
  final int? currentParentId;
  final bool showIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    
    final displayText = truncateProjectMilestoneText(
      projectName: project.title,
      milestoneName: milestone?.title,
    );

    return InkWell(
      onTap: () {
        // 点击时打开选择器
        final picker = ProjectMilestonePicker(
          onSelected: onSelected,
          currentParentId: currentParentId,
        );
        picker.showPickerMenu(context, ref);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                milestone != null ? Icons.flag_outlined : Icons.folder_outlined,
                size: 14,
                color: color,
              ),
            if (showIcon) const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

