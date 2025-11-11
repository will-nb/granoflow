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
      content: const Text(
        '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: const Text('仅归档项目'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('归档项目及活跃任务'),
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
      title: const Text('完成项目'),
      content: const Text(
        '项目下还有活跃任务，是否同时归档所有活跃任务及其子任务？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: const Text('仅完成项目'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('完成项目并归档活跃任务'),
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
      title: const Text('移到回收站'),
      content: const Text(
        '确定要删除这个项目吗？项目将被移到回收站，30天后永久删除。',
      ),
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
      title: const Text('永久删除'),
      content: const Text(
        '确定要永久删除这个项目吗？此操作无法撤销。',
      ),
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

