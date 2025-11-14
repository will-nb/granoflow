import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 项目操作类型
enum ProjectActionType {
  delete,
  archive,
  complete,
}

/// 项目操作确认结果
class ProjectActionConfirmResult {
  const ProjectActionConfirmResult({
    required this.includeSubItems,
  });

  /// 是否包含子项（里程碑和任务）
  final bool includeSubItems;
}

/// 统一的两次确认弹窗
/// 
/// [actionType] 操作类型：删除、归档、完成
/// [project] 项目对象
/// 
/// 返回:
/// - `ProjectActionConfirmResult`: 用户确认并选择包含子项
/// - `null`: 用户取消
Future<ProjectActionConfirmResult?> confirmProjectAction(
  BuildContext context,
  WidgetRef ref,
  ProjectActionType actionType,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final projectService = await ref.read(projectServiceProvider.future);
  final milestoneService = await ref.read(milestoneServiceProvider.future);
  
  // 获取项目下的里程碑和任务
  final milestones = await milestoneService.listByProjectId(project.id);
  final tasks = await projectService.listTasksForProject(project.id);
  
  // 统计活跃的里程碑和任务
  final activeMilestones = milestones.where((m) =>
    m.status == TaskStatus.pending || m.status == TaskStatus.doing
  ).length;
  
  final activeTasks = tasks.where((t) =>
    t.status == TaskStatus.pending ||
    t.status == TaskStatus.doing ||
    t.status == TaskStatus.paused
  ).length;
  
  // 如果没有活跃的里程碑和任务，直接进入第二次确认
  if (activeMilestones == 0 && activeTasks == 0) {
    return await _showSecondConfirmDialog(
      context,
      l10n,
      actionType,
      project,
      includeSubItems: false,
    );
  }
  
  // 第一次确认：询问是否包含子项
  final includeSubItems = await _showFirstConfirmDialog(
    context,
    l10n,
    actionType,
    project,
    activeMilestones,
    activeTasks,
  );
  
  if (includeSubItems == null) {
    // 用户取消
    return null;
  }
  
  // 第二次确认：最终确认
  final confirmed = await _showSecondConfirmDialog(
    context,
    l10n,
    actionType,
    project,
    includeSubItems: includeSubItems,
  );
  
  if (confirmed == null) {
    // 用户取消
    return null;
  }
  
  return ProjectActionConfirmResult(includeSubItems: includeSubItems);
}

/// 第一次确认弹窗
Future<bool?> _showFirstConfirmDialog(
  BuildContext context,
  AppLocalizations l10n,
  ProjectActionType actionType,
  Project project,
  int activeMilestones,
  int activeTasks,
) async {
  String title;
  String message;
  
  switch (actionType) {
    case ProjectActionType.delete:
      title = l10n.projectDeleteFirstConfirmTitle;
      message = l10n.projectDeleteFirstConfirmMessage(
        project.title,
        activeMilestones,
        activeTasks,
      );
      break;
    case ProjectActionType.archive:
      title = l10n.projectArchiveFirstConfirmTitle;
      message = l10n.projectArchiveFirstConfirmMessage(
        project.title,
        activeMilestones,
        activeTasks,
      );
      break;
    case ProjectActionType.complete:
      title = l10n.projectCompleteFirstConfirmTitle;
      message = l10n.projectCompleteFirstConfirmMessage(
        project.title,
        activeMilestones,
        activeTasks,
      );
      break;
  }
  
  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonNo),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.commonYes),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: Text(l10n.commonCancel),
        ),
      ],
    ),
  );
}

/// 第二次确认弹窗
Future<bool?> _showSecondConfirmDialog(
  BuildContext context,
  AppLocalizations l10n,
  ProjectActionType actionType,
  Project project,
  {required bool includeSubItems},
) async {
  String title;
  String message;
  String confirmButtonText;
  Color? confirmButtonColor;
  
  switch (actionType) {
    case ProjectActionType.delete:
      title = l10n.projectDeleteSecondConfirmTitle;
      if (includeSubItems) {
        message = l10n.projectDeleteSecondConfirmMessageWithSubItems(project.title);
      } else {
        message = l10n.projectDeleteSecondConfirmMessageWithoutSubItems(project.title);
      }
      confirmButtonText = l10n.projectDeleteConfirmButton;
      confirmButtonColor = Theme.of(context).colorScheme.error;
      break;
    case ProjectActionType.archive:
      title = l10n.projectArchiveSecondConfirmTitle;
      if (includeSubItems) {
        message = l10n.projectArchiveSecondConfirmMessageWithSubItems(project.title);
      } else {
        message = l10n.projectArchiveSecondConfirmMessageWithoutSubItems(project.title);
      }
      confirmButtonText = l10n.projectArchiveConfirmButton;
      confirmButtonColor = null;
      break;
    case ProjectActionType.complete:
      title = l10n.projectCompleteSecondConfirmTitle;
      if (includeSubItems) {
        message = l10n.projectCompleteSecondConfirmMessageWithSubItems(project.title);
      } else {
        message = l10n.projectCompleteSecondConfirmMessageWithoutSubItems(project.title);
      }
      confirmButtonText = l10n.projectCompleteConfirmButton;
      confirmButtonColor = null;
      break;
  }
  
  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: confirmButtonColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmButtonColor)
              : null,
          child: Text(confirmButtonText),
        ),
      ],
    ),
  );
}

// 保留旧的函数以保持向后兼容，但标记为已废弃
@Deprecated('Use confirmProjectAction instead')
Future<bool?> confirmProjectArchive(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final result = await confirmProjectAction(
    context,
    ref,
    ProjectActionType.archive,
    project,
  );
  if (result == null) return null;
  return result.includeSubItems;
}

@Deprecated('Use confirmProjectAction instead')
Future<bool?> confirmProjectComplete(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final result = await confirmProjectAction(
    context,
    ref,
    ProjectActionType.complete,
    project,
  );
  if (result == null) return null;
  return result.includeSubItems;
}

/// 确认将项目移到回收站对话框
Future<bool> confirmProjectTrash(
  BuildContext context,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectTrashTitle),
      content: Text(l10n.projectTrashConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.actionMoveToTrash),
        ),
      ],
    ),
  );
  return result == true;
}

/// 确认永久删除项目对话框
Future<bool> confirmProjectDelete(
  BuildContext context,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectDeletePermanentTitle),
      content: Text(l10n.projectDeletePermanentMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.trashPermanentDeleteAction),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ),
  );
  return result == true;
}

