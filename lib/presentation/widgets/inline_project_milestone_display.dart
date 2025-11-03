import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/project_models.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import 'project_milestone_picker.dart';
import 'project_milestone_text_utils.dart';

/// 可内联编辑的项目/里程碑显示组件
/// 风格与 InlineDeadlineEditor 和 InlineEditableTag 一致（Minimal 风格）
class InlineProjectMilestoneDisplay extends ConsumerWidget {
  const InlineProjectMilestoneDisplay({
    super.key,
    required this.project,
    this.milestone,
    required this.onSelected,
    this.showIcon = true,
    this.readOnly = false,
  });

  final Project project;
  final Milestone? milestone;
  final ValueChanged<ProjectMilestoneSelection?> onSelected;
  final bool showIcon;
  
  /// 是否只读模式（不显示点击交互，但保持视觉样式）
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    final displayText = truncateProjectMilestoneText(
      projectName: project.title,
      milestoneName: milestone?.title,
    );

    final content = Padding(
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
    );

    // 只读模式：不包装InkWell，直接返回内容
    if (readOnly) {
      return content;
    }

    // 可编辑模式：包装InkWell，支持点击交互
    return InkWell(
      onTap: () {
        ProjectMilestonePicker(
          onSelected: onSelected,
          currentProjectId: project.projectId,
          currentMilestoneId: milestone?.milestoneId,
        ).showPickerMenu(context, ref);
      },
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
