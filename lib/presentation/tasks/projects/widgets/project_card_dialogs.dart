import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/project.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 确认归档项目对话框
/// 
/// 如果项目下有活跃任务，会询问是否同时归档活跃任务。
/// 返回:
/// - `true`: 归档项目及活跃任务
/// - `false`: 用户取消
/// - `null`: 仅归档项目（不归档活跃任务）
Future<bool?> confirmProjectArchive(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final projectService = await ref.read(projectServiceProvider.future);
  final hasActiveTasks = await projectService.hasActiveTasks(project.id);

  if (!hasActiveTasks) {
    // 没有活跃任务，直接确认
    return true;
  }

  // 有活跃任务，弹出确认对话框询问是否归档活跃任务
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectArchiveConfirmTitle),
      content: Text(l10n.projectArchiveConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: Text(l10n.projectArchiveOnly),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.projectArchiveWithTasks),
        ),
      ],
    ),
  );
  return result;
}

/// 确认完成项目对话框
/// 
/// 如果项目下有活跃任务，会询问是否同时归档活跃任务。
/// 返回:
/// - `true`: 完成项目并归档活跃任务
/// - `false`: 用户取消
/// - `null`: 仅完成项目（不归档活跃任务）
Future<bool?> confirmProjectComplete(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final projectService = await ref.read(projectServiceProvider.future);
  final hasActiveTasks = await projectService.hasActiveTasks(project.id);

  if (!hasActiveTasks) {
    // 没有活跃任务，直接确认
    return true;
  }

  // 有活跃任务，弹出确认对话框询问是否归档活跃任务
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectCompleteTitle),
      content: Text(l10n.projectCompleteConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: Text(l10n.projectCompleteOnly),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.projectCompleteWithTasks),
        ),
      ],
    ),
  );
  return result;
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

