import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 归档项目
Future<void> archiveProject(
  BuildContext context,
  WidgetRef ref,
  String projectId, {
  bool archiveTasks = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final projectService = await ref.read(projectServiceProvider.future);
    await projectService.archiveProject(projectId, archiveActiveTasks: archiveTasks);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskArchivedToast)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to archive project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskArchivedError)),
    );
  }
}

/// 完成项目
Future<void> completeProject(
  BuildContext context,
  WidgetRef ref,
  String projectId, {
  bool archiveTasks = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await ref
        .read(projectServiceProvider)
        .completeProject(projectId, archiveActiveTasks: archiveTasks);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.actionMarkCompleted)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to complete project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskCompletedError)),
    );
  }
}

/// 将项目移到回收站
Future<void> trashProject(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final projectService = await ref.read(projectServiceProvider.future);
    await projectService.trashProject(projectId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.actionMoveToTrash)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to trash project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskArchivedError)),
    );
  }
}

/// 恢复项目
Future<void> restoreProject(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final projectService = await ref.read(projectServiceProvider.future);
    await projectService.restoreProject(projectId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trashRestoreSuccess)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to restore project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trashRestoreError)),
    );
  }
}

/// 重新激活项目（将已完成或归档的项目恢复到 pending 状态）
Future<void> reactivateProject(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final projectService = await ref.read(projectServiceProvider.future);
    await projectService.reactivateProject(projectId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trashRestoreSuccess)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to reactivate project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trashRestoreError)),
    );
  }
}

/// 永久删除项目
Future<void> deleteProject(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final projectService = await ref.read(projectServiceProvider.future);
    await projectService.deleteProject(projectId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('项目已永久删除')),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to delete project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trashRestoreError)),
    );
  }
}

