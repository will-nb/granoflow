import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ocean_breeze_color_schemes.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';
import 'project_card_actions.dart';
import 'project_card_dialogs.dart';

/// 项目滑动配置
class ProjectSwipeConfig {
  const ProjectSwipeConfig({
    required this.leftColor,
    required this.leftIcon,
    required this.leftLabel,
    required this.rightColor,
    required this.rightIcon,
    required this.rightLabel,
  });

  final Color leftColor;
  final IconData leftIcon;
  final String leftLabel;
  final Color rightColor;
  final IconData rightIcon;
  final String rightLabel;
}

/// 获取项目的滑动配置
ProjectSwipeConfig getProjectSwipeConfig(
  Project project,
  ThemeData theme,
  AppLocalizations l10n,
) {
  final isActive = project.status == TaskStatus.pending ||
      project.status == TaskStatus.doing;
  final isArchived = project.status == TaskStatus.archived;
  final isTrashed = project.status == TaskStatus.trashed;
  final isCompleted = project.status == TaskStatus.completedActive;

  if (isActive) {
    // 活跃项目：右侧完成，左侧归档
    return ProjectSwipeConfig(
      leftColor: OceanBreezeColorSchemes.softPink,
      leftIcon: Icons.archive_outlined,
      leftLabel: l10n.taskArchiveAction,
      rightColor: OceanBreezeColorSchemes.softGreen,
      rightIcon: Icons.check_circle_outline,
      rightLabel: l10n.actionMarkCompleted,
    );
  } else if (isArchived) {
    // 归档项目：右侧重启，左侧移入回收站
    return ProjectSwipeConfig(
      leftColor: OceanBreezeColorSchemes.errorDark,
      leftIcon: Icons.delete_outline,
      leftLabel: l10n.actionMoveToTrash,
      rightColor: OceanBreezeColorSchemes.softGreen,
      rightIcon: Icons.restore_outlined,
      rightLabel: l10n.trashRestoreAction,
    );
  } else if (isTrashed) {
    // 回收站：右侧重启，左侧删除
    return ProjectSwipeConfig(
      leftColor: OceanBreezeColorSchemes.errorDark,
      leftIcon: Icons.delete_forever,
      leftLabel: l10n.trashPermanentDeleteAction,
      rightColor: OceanBreezeColorSchemes.softGreen,
      rightIcon: Icons.restore_outlined,
      rightLabel: l10n.trashRestoreAction,
    );
  } else if (isCompleted) {
    // 完成项目：右侧重启，左侧移入回收站
    return ProjectSwipeConfig(
      leftColor: OceanBreezeColorSchemes.errorDark,
      leftIcon: Icons.delete_outline,
      leftLabel: l10n.actionMoveToTrash,
      rightColor: OceanBreezeColorSchemes.softGreen,
      rightIcon: Icons.restore_outlined,
      rightLabel: l10n.trashRestoreAction,
    );
  }

  // 默认配置（不应该到达这里）
  return ProjectSwipeConfig(
    leftColor: theme.colorScheme.primary,
    leftIcon: Icons.archive_outlined,
    leftLabel: l10n.taskArchiveAction,
    rightColor: theme.colorScheme.tertiary,
    rightIcon: Icons.snooze,
    rightLabel: l10n.projectSnoozeAction,
  );
}

/// 处理项目滑动操作
Future<bool> handleProjectSwipeAction(
  BuildContext context,
  WidgetRef ref,
  DismissDirection direction,
  Project project,
  ProjectSwipeConfig config,
) async {
  final isActive = project.status == TaskStatus.pending ||
      project.status == TaskStatus.doing;
  final isArchived = project.status == TaskStatus.archived;
  final isTrashed = project.status == TaskStatus.trashed;
  final isCompleted = project.status == TaskStatus.completedActive;

  if (direction == DismissDirection.startToEnd) {
    // 右滑（左侧操作）
    if (isActive) {
      // 活跃项目：归档
      final confirmed = await confirmProjectArchive(context, ref, project);
      if (confirmed == null || confirmed == false) {
        return false;
      }
      await archiveProject(
        context,
        ref,
        project.id,
        archiveTasks: confirmed == true,
      );
      return true;
    } else if (isArchived || isCompleted) {
      // 归档/完成项目：移入回收站
      final confirmed = await confirmProjectTrash(context, project);
      if (!confirmed) {
        return false;
      }
      await trashProject(context, ref, project.id);
      return true;
    } else if (isTrashed) {
      // 回收站：删除
      final confirmed = await confirmProjectDelete(context, project);
      if (!confirmed) {
        return false;
      }
      await deleteProject(context, ref, project.id);
      return true;
    }
  } else if (direction == DismissDirection.endToStart) {
    // 左滑（右侧操作）
    if (isActive) {
      // 活跃项目：完成
      final confirmed = await confirmProjectComplete(context, ref, project);
      if (confirmed == null || confirmed == false) {
        return false;
      }
      await completeProject(
        context,
        ref,
        project.id,
        archiveTasks: confirmed == true,
      );
      return true;
    } else if (isArchived || isCompleted) {
      // 归档/完成项目：重启
      await reactivateProject(context, ref, project.id);
      return true;
    } else if (isTrashed) {
      // 回收站：重启
      await restoreProject(context, ref, project.id);
      return true;
    }
  }

  return false;
}

